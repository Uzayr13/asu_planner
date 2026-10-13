---
name: markitdown
description: Convert any document format to readable markdown. Use when reading pptx, docx, xlsx, xls, pdf, Outlook MSG, or any file format supported by Microsoft's MarkItDown library. This is mandatory — never use the Read tool on these formats directly.
triggers:
  - file extension: .pptx
  - file extension: .docx
  - file extension: .xlsx
  - file extension: .xls
  - file extension: .pdf
  - file extension: .msg
  - file extension: .eml
  - file type: Azure Document Intelligence
  - file type: Azure Content Understanding
  - file type: audio transcription
  - file type: YouTube transcription
---

# MarkItDown — Universal Document Converter

Use Microsoft's [MarkItDown](https://github.com/microsoft/markitdown) to convert any supported file format to markdown before reading.

## When To Use

This skill is MANDATORY for reading any of these file types:
- **Office**: `.pptx`, `.docx`, `.xlsx`, `.xls`
- **Email**: `.msg`, `.eml`
- **PDF**: `.pdf` (when built-in PDF reader fails or produces garbage)
- **Media transcripts**: YouTube transcripts, audio transcription output
- **Azure**: Document Intelligence / Content Understanding outputs

Never attempt to read these formats with the Read tool directly. Use markitdown first.

## How To Use

### Step 1 — Convert to markdown

```bash
python -m markitdown "INPUT_FILE_PATH" -o "OUTPUT_MD_PATH"
```

Replace `INPUT_FILE_PATH` with the absolute path to the file, and `OUTPUT_MD_PATH` with a temporary `.md` path (e.g., `/tmp/markitdown_output.md`).

### Step 2 — Read the markdown

Use the Read tool on `OUTPUT_MD_PATH` to read the converted content.

### Step 3 — Clean up (optional)

```bash
rm "OUTPUT_MD_PATH"
```

## Supported Formats

| Format | Extension | Notes |
|---|---|---|
| PowerPoint | `.pptx` | Slides converted to markdown with headings |
| Word | `.docx` | Full document with formatting |
| Excel | `.xlsx`, `.xls` | Tables converted to markdown tables |
| PDF | `.pdf` | Text extraction with layout preservation |
| Outlook | `.msg` | Email body + metadata |
| Email | `.eml` | Email body + headers |
| Images | `.png`, `.jpg`, etc. | OCR via optional plugin |
| Audio | `.wav`, `.mp3` | Transcription via optional plugin |
| ZIP | `.zip` | Iterates over contained files |

## Example

```
User: "Read this quarterly report: e:\docs\report.pptx"

Claude:
  1. python -m markitdown "e:\docs\report.pptx" -o "/tmp/report.md"
  2. Read /tmp/report.md
  3. Present content to user
```
