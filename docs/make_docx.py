#!/usr/bin/env python3
"""Wersja Word sprawozdania: Typst -> HTML (wzory jako MathML) -> pandoc -> .docx.

Uzycie: python3 make_docx.py plik.typ wynik.docx
Wymaga: typst (>= 0.14, eksport HTML), pandoc.
"""
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

FONT = "Times New Roman"


def reference_docx(path):
    """Szablon stylow: Times New Roman 12 pt, czarne pogrubione naglowki, styl Tytul (wysrodkowany)."""
    subprocess.run(["pandoc", "-o", str(path), "--print-default-data-file", "reference.docx"], check=True)
    with zipfile.ZipFile(path) as z:
        files = {n: z.read(n) for n in z.namelist()}
    st = files["word/styles.xml"].decode()
    # domyslna czcionka i rozmiar
    st = re.sub(r'<w:rFonts [^>]*/>', f'<w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}" w:eastAsia="{FONT}" w:cs="{FONT}"/>', st)
    st = re.sub(r'<w:sz w:val="\d+"\s*/>', '<w:sz w:val="24"/>', st, count=1)
    st = re.sub(r'<w:szCs w:val="\d+"\s*/>', '<w:szCs w:val="24"/>', st, count=1)
    # naglowki czarne, pogrubione, 13/12/12 pt
    st = re.sub(r'<w:color w:val="[0-9A-Fa-f]{6}"\s*(w:themeColor="[^"]*"\s*)?(w:themeShade="[^"]*"\s*)?/>', '<w:color w:val="000000"/>', st)
    for lvl, sz in (("1", 26), ("2", 26), ("3", 24), ("4", 24)):
        st = re.sub(rf'(<w:style w:type="paragraph" w:styleId="Heading{lvl}">.*?<w:rPr>)(.*?)(</w:rPr>)',
                    rf'\1<w:b/><w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>\3', st, flags=re.S)
    st = re.sub(r'<w:i\s*/>', '', st)   # bez kursywy w podpisach i naglowkach
    # tabele: wysrodkowane, z obramowaniem, pogrubiony wiersz naglowka
    ram = ''.join(f'<w:{b} w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
                  for b in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'))
    st = re.sub(r'(<w:style w:type="table" w:default="1" w:styleId="Table">.*?<w:tblPr>)\s*(<w:tblInd [^>]*/>)',
                rf'\1<w:jc w:val="center"/>\2<w:tblBorders>{ram}</w:tblBorders>', st, flags=re.S)
    st = st.replace('<w:tblStylePr w:type="firstRow">', '<w:tblStylePr w:type="firstRow"><w:rPr><w:b/></w:rPr>', 1)
    tytul = ('<w:style w:type="paragraph" w:customStyle="1" w:styleId="Tytul"><w:name w:val="Tytul"/>'
             '<w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/><w:spacing w:before="240" w:after="240"/></w:pPr>'
             '<w:rPr><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>')
    # tabela-ramka, w ktorej pandoc umieszcza rysunki i tabele z podpisem: bez obramowania
    bez = ''.join(f'<w:{b} w:val="nil"/>' for b in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'))
    ramka = ('<w:style w:type="table" w:customStyle="1" w:styleId="FigureTable"><w:name w:val="Figure Table"/>'
             f'<w:basedOn w:val="TableNormal"/><w:tblPr><w:jc w:val="center"/><w:tblBorders>{bez}</w:tblBorders></w:tblPr></w:style>')
    st = st.replace("</w:styles>", tytul + ramka + "</w:styles>")
    files["word/styles.xml"] = st.encode()
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for n, d in files.items():
            z.writestr(n, d)


def main(typ, out):
    typ, out = Path(typ).resolve(), Path(out).resolve()
    with tempfile.TemporaryDirectory() as tmp:
        html, ref = Path(tmp) / "s.html", Path(tmp) / "ref.docx"
        subprocess.run(["typst", "compile", "--features", "html", "--format", "html", str(typ), str(html)],
                       check=True, cwd=typ.parent, capture_output=True)
        s = html.read_text()
        # rozmiar obrazkow jak w PDF (procent szerokosci tekstu), zamiast rozmiaru w pikselach
        s = re.sub(r'<img src="([^"]+)" width="\d+" height="\d+" style="display: block; width: (\d+)%">',
                   r'<img src="\1" style="width: \2%">', s)
        s = re.sub(r'<title>.*?</title>', '', s)   # bez dodatkowego tytulu z metadanych
        s = re.sub(r'<meta name="authors"[^>]*>', '', s)
        html.write_text(s)
        reference_docx(ref)
        subprocess.run(["pandoc", str(html), "-f", "html", "-o", str(out), "--reference-doc", str(ref)], check=True)
    # podzial strony po stronie tytulowej, wysrodkowane rysunki i podpisy
    with zipfile.ZipFile(out) as z:
        files = {n: z.read(n) for n in z.namelist() if not n.endswith("/")}
    d = files["word/document.xml"].decode()
    tyt = list(re.finditer(r'<w:p>(?:(?!</w:p>).)*?<w:pStyle w:val="Tytul"\s*/>.*?</w:p>', d, flags=re.S))
    if tyt:
        e = tyt[-1].end()
        d = d[:e] + '<w:p><w:r><w:br w:type="page"/></w:r></w:p>' + d[e:]
    # podpis tabeli nad tabela (jak w PDF): akapit 'Tabela N:' przenosimy przed otaczajaca tabele rysunku
    poz = 0
    while True:
        m = re.compile(r'>Tabela[\s\u00a0]\d').search(d, poz)
        if not m:
            break
        i = m.start()
        p0 = d.rfind('<w:p>', 0, i)
        p1 = d.find('</w:p>', i) + len('</w:p>')
        if d[:p0].rstrip().endswith('</w:tbl>'):
            t0 = d.rfind('<w:tbl><w:tblPr><w:tblStyle w:val="FigureTable"', 0, p0)
            akapit = d[p0:p1].replace('w:val="ImageCaption"', 'w:val="TableCaption"')
            d = d[:t0] + akapit + d[t0:p0] + d[p1:]
            poz = p1
        else:
            poz = i + 1
    for sty in ("CaptionedFigure", "ImageCaption", "TableCaption", "Figure"):
        d = d.replace(f'<w:pStyle w:val="{sty}" />', f'<w:pStyle w:val="{sty}" /><w:jc w:val="center" />')
    files["word/document.xml"] = d.encode()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for n, data in files.items():
            z.writestr(n, data)
    print(f"Zapisano {out}")


if __name__ == "__main__":
    main(*sys.argv[1:3])
