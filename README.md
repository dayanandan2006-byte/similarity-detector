# SRMIST Tiruchirappalli — AI Project Idea Duplicate Detector & Entity Resolution System
### DBMS Mini-Project (Department of Artificial Intelligence, 3rd Year 2026–2027)
**Faculty Guide:** Dr. S.P. Ramya  
**Institutional High-Risk Threshold:** Similarity $\ge 80.0\%$ (Flagged in RED)

---

## 🌟 Overview & DBMS Architecture

This project is a 3NF-normalized Database Management System (DBMS) integrated with an AI-driven Duplicate Detection & Entity Resolution engine. It evaluates student capstone and mini-project submissions, detects redundant ideas using dense vector embeddings, and enables faculty guides to merge overlapping project groups into unified research teams.

### Key Highlights:
1. **Relational Database in 3NF**: 10 normalized tables (`departments`, `faculty_guides`, `domains`, `student_teams`, `students`, `entity_concepts`, `proposals`, `similarity_logs`, `faculty_reviews`, `system_audit_logs`).
2. **Relational SQL Views**:
   - `v_flagged_duplicates`: Real-time filter of proposals $\ge 80.0\%$ similarity.
   - `v_domain_analytics`: Domain-wise aggregate risk percentages and counts.
   - `v_project_summary`: Complete catalog joined with student leads and guides.
   - `v_audit_history`: Complete audit trail of system and faculty actions.
3. **Automated Triggers**:
   - `trg_proposal_status_audit`: Automatically records every status transition into `system_audit_logs`.
   - `trg_similarity_threshold_check`: Automatically flags duplicate proposals when similarity exceeds $80.0\%$.
4. **Interactive SQL Console**: Live SQL runner in the frontend allowing evaluators and students to run `SELECT` queries directly against the database with millisecond timing.
5. **Dual-Mode Engine (Server API + WebAssembly SQLite)**:
   - When run with `python server.py`, connects to FastAPI and SQLite.
   - When deployed to static **GitHub Pages**, initializes WebAssembly SQLite (`sql.js`) in-browser so that real SQL queries execute with 100% zero-configuration uptime!

---

## 🚀 Quick Start Guide

### 1. Local Run with Python (FastAPI + SQLite)
```powershell
# Navigate to project folder
cd C:\Users\dayan\.gemini\antigravity\scratch\ai-project-duplicate-detector-dbms

# Install requirements
pip install -r requirements.txt

# Start the server
python server.py
```
Open your browser at: **`http://localhost:8000`**

### 2. Updating your GitHub Pages Repository
To update your live website at `https://dayanandan2006-byte.github.io/Duplicate-detector/`:
1. Copy `index.html` from this folder.
2. In your GitHub repository (`dayanandan2006-byte/Duplicate-detector`), replace `index.html` and commit changes.
3. Your live GitHub Pages site will instantly have the new DBMS SQL Console, ER Schema Explorer, and WebAssembly SQLite query runner!

---

## 📁 File Structure
- `schema.sql`: Complete DDL and DML benchmark script (3NF, Views, Triggers, Indexes).
- `server.py`: FastAPI REST API connecting to SQLite.
- `index.html`: Responsive single-page application with DBMS Console, Batch Comparator, Pairwise Analyzer, and Review Console.
- `DBMS_PROJECT_REPORT.md`: Comprehensive academic DBMS project documentation ready for viva/evaluation.
- `Dockerfile`: Pre-configured container for Hugging Face Spaces / Render.
- `requirements.txt`: Python package requirements.
