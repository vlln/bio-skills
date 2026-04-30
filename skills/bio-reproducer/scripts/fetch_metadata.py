#!/usr/bin/env python3
"""Resolve paper-provided DOI/accession identifiers for Phase 1 plan records."""
import argparse
import json

import requests

DB_URLS = {
    'sra': 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils',
    'ena': 'https://www.ebi.ac.uk/ena/portal/api',
    'geo': 'https://www.ncbi.nlm.nih.gov/geo/query',
    'doi': 'https://api.crossref.org/works'
}

TIMEOUT = 30

def fetch_sra(acc: str) -> dict:
    """从 SRA 获取标识符记录"""
    r = requests.get(f"{DB_URLS['sra']}/esearch.fcgi",
                     params={'db': 'sra', 'term': acc, 'retmode': 'json'}, timeout=TIMEOUT)
    data = r.json().get('esearchresult', {}).get('idlist', [])
    if not data: return {'error': f'No ID for {acc}'}
    
    r = requests.get(f"{DB_URLS['sra']}/esummary.fcgi",
                     params={'db': 'sra', 'id': data[0], 'retmode': 'json'}, timeout=TIMEOUT)
    result = r.json().get('result', {}).get(data[0], {})
    
    return {
        'accession': acc, 'source': 'SRA',
        'title': result.get('title', ''),
        'platform': result.get('platform', {}).get('model_name', ''),
        'library_strategy': result.get('library_strategy', ''),
        'total_spots': result.get('total_spots', ''),
        'links': _sra_links(acc)
    }

def _sra_links(acc: str) -> list:
    """SRA public record links. These are metadata hints, not a download plan."""
    prefix = acc[:6]
    suffix = acc[-3:] if len(acc) >= 9 else acc[-2:]
    return [
        {'url': f"ftp://ftp.sra.ebi.ac.uk/vol1/fastq/{prefix}/{suffix}/{acc}/", 'src': 'ENA'},
        {'url': f"s3://sra-pub-run-odp/sra/{acc}/{acc}", 'src': 'AWS'},
    ]
def fetch_ena(acc: str) -> dict:
    """从 ENA 获取标识符记录"""
    r = requests.get(f"{DB_URLS['ena']}/filereport",
                     params={'accession': acc, 'result': 'read_run',
                     'fields': 'run_accession,fastq_ftp,fastq_md5,read_count,base_count'}, timeout=TIMEOUT)
    lines = r.text.strip().split('\n')
    if len(lines) < 2: return {'error': 'No data'}
    
    header = lines[0].split('\t')
    runs = [dict(zip(header, l.split('\t'))) for l in lines[1:]]
    return {'accession': acc, 'source': 'ENA', 'runs': runs}
def fetch_geo(acc: str) -> dict:
    """从 GEO 获取标识符记录"""
    r = requests.get(DB_URLS['geo'], params={'acc': acc, 'view': 'full', 'form': 'text'}, timeout=TIMEOUT)
    meta = {'accession': acc, 'source': 'GEO'}
    for line in r.text.split('\n'):
        if line.startswith('!') and '=' in line:
            k, v = line[1:].split('=', 1)
            meta[k.strip()] = v.strip()
    return meta
def fetch_doi(doi: str) -> dict:
    """从 CrossRef 获取 DOI 标识符记录"""
    r = requests.get(f"{DB_URLS['doi']}/{doi}", timeout=TIMEOUT)
    work = r.json().get('message', {})
    return {
        'doi': doi, 'title': work.get('title', [''])[0],
        'authors': [f"{a.get('given','')} {a.get('family','')}" for a in work.get('author', [])],
        'year': work.get('published-print', {}).get('date-parts', [[None]])[0][0],
    }
def format_meta(meta: dict, fmt: str) -> str:
    """格式化为可复制进 plan.md External Identifier Records 的输出"""
    if fmt == 'json': return json.dumps(meta, indent=2, ensure_ascii=False)
    
    lines = [f"# {meta.get('accession', meta.get('doi', 'N/A'))}"]
    lines.append(f"Source: {meta.get('source', 'DOI')}")
    for k, v in meta.items():
        if k not in ('runs', 'links', 'error') and v:
            lines.append(f"| {k} | {v} |")
    if 'links' in meta:
        lines.append("\n## Links")
        for l in meta['links']:
            lines.append(f"| {l['src']} | {l['url']} |")
    if 'runs' in meta:
        lines.append("\n## Runs")
        for run in meta['runs']:
            lines.append(f"| {run.get('run_accession', '')} | {run.get('fastq_ftp', '')} |")
    if 'error' in meta:
        lines.append(f"\n**Error: {meta['error']}")
    return '\n'.join(lines)
def main():
    ap = argparse.ArgumentParser(
        description='Resolve paper-provided DOI/accession identifiers for plan.md records'
    )
    ap.add_argument('db', choices=['sra', 'ena', 'geo', 'doi'], help='数据库')
    ap.add_argument('acc', nargs='+', help='访问号')
    ap.add_argument('-f', choices=['text', 'json', 'markdown'], default='markdown', help='格式')
    args = ap.parse_args()

    for a in args.acc:
        print(f"Fetching {a}...")
        m = {'sra': fetch_sra, 'ena': fetch_ena, 'geo': fetch_geo, 'doi': fetch_doi}[args.db](a)
        print(format_meta(m, args.f))

if __name__ == '__main__':
    main()
