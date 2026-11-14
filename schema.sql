-- ============================================================================
-- SRM INSTITUTE OF SCIENCE AND TECHNOLOGY - TIRUCHIRAPPALLI CAMPUS
-- DEPARTMENT OF ARTIFICIAL INTELLIGENCE (3rd Year, 2026-2027)
-- Course: Database Management Systems (DBMS) Mini-Project
-- Project: AI Project Idea Duplicate Detector & Entity Resolution System
-- Guide: Dr. S.P. Ramya
-- Standard: Relational Schema in 3rd Normal Form (3NF) with Triggers & Views
-- ============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ----------------------------------------------------------------------------
-- 1. DROP EXISTING OBJECTS (CLEAN REBUILD)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_flagged_duplicates;
DROP VIEW IF EXISTS v_project_summary;
DROP VIEW IF EXISTS v_domain_analytics;
DROP VIEW IF EXISTS v_merged_teams_roster;
DROP VIEW IF EXISTS v_audit_history;

DROP TRIGGER IF EXISTS trg_proposal_status_audit;
DROP TRIGGER IF EXISTS trg_faculty_review_audit;
DROP TRIGGER IF EXISTS trg_team_merge_audit;

DROP TABLE IF EXISTS system_audit_logs;
DROP TABLE IF EXISTS faculty_reviews;
DROP TABLE IF EXISTS similarity_logs;
DROP TABLE IF EXISTS proposals;
DROP TABLE IF EXISTS entity_concepts;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS student_teams;
DROP TABLE IF EXISTS domains;
DROP TABLE IF EXISTS faculty_guides;
DROP TABLE IF EXISTS departments;

-- ----------------------------------------------------------------------------
-- 2. CORE RELATIONAL TABLES (3NF NORMALIZATION)
-- ----------------------------------------------------------------------------

-- Table 1: Academic Departments
CREATE TABLE departments (
    dept_id VARCHAR(10) PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    institution VARCHAR(100) NOT NULL DEFAULT 'SRMIST Tiruchirappalli'
);

-- Table 2: Faculty Guides / Supervisors
CREATE TABLE faculty_guides (
    guide_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    dept_id VARCHAR(10) NOT NULL,
    designation VARCHAR(60) NOT NULL DEFAULT 'Associate Professor',
    specialization VARCHAR(100) DEFAULT 'Machine Learning & Natural Language Processing',
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON UPDATE CASCADE
);

-- Table 3: Academic Research Domains
CREATE TABLE domains (
    domain_id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain_name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(60) NOT NULL DEFAULT 'Artificial Intelligence',
    description TEXT,
    coordinator_id INTEGER,
    FOREIGN KEY (coordinator_id) REFERENCES faculty_guides(guide_id) ON DELETE SET NULL
);

-- Table 4: Student Project Teams
CREATE TABLE student_teams (
    team_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_name VARCHAR(100) NOT NULL,
    guide_id INTEGER,
    status VARCHAR(30) NOT NULL DEFAULT 'Active', -- 'Active', 'Merged', 'Disbanded'
    merged_with_team_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (guide_id) REFERENCES faculty_guides(guide_id) ON DELETE SET NULL,
    FOREIGN KEY (merged_with_team_id) REFERENCES student_teams(team_id) ON DELETE SET NULL
);

-- Table 5: Students
CREATE TABLE students (
    reg_no VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    team_id INTEGER,
    is_team_lead BOOLEAN DEFAULT 0,
    dept_id VARCHAR(10) NOT NULL DEFAULT 'CSE-AI',
    year_of_study INTEGER DEFAULT 3,
    FOREIGN KEY (team_id) REFERENCES student_teams(team_id) ON DELETE SET NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Table 6: Academic Entity Resolution Concepts (Pre-calibrated NLP Clusters)
CREATE TABLE entity_concepts (
    concept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    concept_name VARCHAR(150) UNIQUE NOT NULL,
    domain_id INTEGER,
    core_terms TEXT NOT NULL,       -- Comma-separated domain nouns
    technical_terms TEXT NOT NULL,  -- Comma-separated algorithms/tech
    institutional_risk_weight REAL DEFAULT 1.0,
    FOREIGN KEY (domain_id) REFERENCES domains(domain_id) ON DELETE SET NULL
);

-- Table 7: Project Proposals
CREATE TABLE proposals (
    proposal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL,
    domain_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    problem_statement TEXT NOT NULL,
    methodology TEXT,
    full_description TEXT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Approved', -- 'Approved', 'Flagged Duplicate', 'Merged Team', 'Under Faculty Review'
    highest_similarity_score REAL DEFAULT 0.0,
    matched_proposal_id INTEGER,
    embedding_json TEXT, -- 384-dimensional dense semantic embedding vector
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES student_teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (domain_id) REFERENCES domains(domain_id) ON UPDATE CASCADE,
    FOREIGN KEY (matched_proposal_id) REFERENCES proposals(proposal_id) ON DELETE SET NULL
);

-- Table 8: Pairwise Similarity & Duplicate Evaluation Logs
CREATE TABLE similarity_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_proposal_id INTEGER NOT NULL,
    target_proposal_id INTEGER NOT NULL,
    semantic_score REAL NOT NULL,
    objective_similarity REAL NOT NULL,
    methodology_similarity REAL NOT NULL,
    matched_concept_id INTEGER,
    final_calibrated_score REAL NOT NULL,
    is_high_risk_flag BOOLEAN NOT NULL DEFAULT 0, -- 1 if >= 80.0
    evaluator_engine VARCHAR(60) DEFAULT 'Hybrid Multi-Signal AI + Concept Matcher',
    evaluation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (source_proposal_id) REFERENCES proposals(proposal_id) ON DELETE CASCADE,
    FOREIGN KEY (target_proposal_id) REFERENCES proposals(proposal_id) ON DELETE CASCADE,
    FOREIGN KEY (matched_concept_id) REFERENCES entity_concepts(concept_id) ON DELETE SET NULL
);

-- Table 9: Faculty Reviews & Entity Resolution Decisions
CREATE TABLE faculty_reviews (
    review_id INTEGER PRIMARY KEY AUTOINCREMENT,
    proposal_id INTEGER NOT NULL,
    guide_id INTEGER NOT NULL,
    decision VARCHAR(40) NOT NULL, -- 'Approved', 'Flagged Duplicate', 'Merged Team', 'Rejected'
    remarks TEXT,
    merged_with_proposal_id INTEGER,
    review_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (proposal_id) REFERENCES proposals(proposal_id) ON DELETE CASCADE,
    FOREIGN KEY (guide_id) REFERENCES faculty_guides(guide_id) ON UPDATE CASCADE,
    FOREIGN KEY (merged_with_proposal_id) REFERENCES proposals(proposal_id) ON DELETE SET NULL
);

-- Table 10: DBMS Audit Logs (System Action History)
CREATE TABLE system_audit_logs (
    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name VARCHAR(50) NOT NULL,
    action_type VARCHAR(30) NOT NULL, -- 'INSERT', 'UPDATE', 'STATUS_CHANGE', 'TEAM_MERGE'
    record_id INTEGER,
    details TEXT NOT NULL,
    performed_by VARCHAR(100) DEFAULT 'System / Dr. S.P. Ramya',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 3. INDEXES FOR PERFORMANCE OPTIMIZATION
-- ----------------------------------------------------------------------------
CREATE INDEX idx_proposals_domain ON proposals(domain_id);
CREATE INDEX idx_proposals_status ON proposals(status);
CREATE INDEX idx_proposals_score ON proposals(highest_similarity_score);
CREATE INDEX idx_similarity_source ON similarity_logs(source_proposal_id);
CREATE INDEX idx_similarity_target ON similarity_logs(target_proposal_id);
CREATE INDEX idx_students_team ON students(team_id);

-- ----------------------------------------------------------------------------
-- 4. RELATIONAL VIEWS (FOR DBMS REPORTING & AGGREGATION)
-- ----------------------------------------------------------------------------

-- View 1: High Risk Duplicates (Similarity >= 80% or Status Flagged)
CREATE VIEW v_flagged_duplicates AS
SELECT 
    p.proposal_id,
    p.title AS proposal_title,
    t.team_name,
    s.reg_no AS lead_reg_no,
    s.full_name AS lead_student_name,
    d.domain_name,
    p.highest_similarity_score,
    p.status AS proposal_status,
    p.matched_proposal_id,
    mp.title AS matched_proposal_title,
    mt.team_name AS matched_team_name,
    p.submitted_at
FROM proposals p
JOIN student_teams t ON p.team_id = t.team_id
LEFT JOIN students s ON s.team_id = t.team_id AND s.is_team_lead = 1
JOIN domains d ON p.domain_id = d.domain_id
LEFT JOIN proposals mp ON p.matched_proposal_id = mp.proposal_id
LEFT JOIN student_teams mt ON mp.team_id = mt.team_id
WHERE p.highest_similarity_score >= 80.0 OR p.status = 'Flagged Duplicate';

-- View 2: Complete Project Summary View (Joined Catalog)
CREATE VIEW v_project_summary AS
SELECT 
    p.proposal_id,
    p.title,
    p.full_description,
    d.domain_name,
    d.category AS domain_category,
    t.team_id,
    t.team_name,
    COALESCE(lead.full_name, 'Unassigned') AS lead_name,
    COALESCE(lead.reg_no, 'N/A') AS lead_reg_no,
    g.name AS faculty_guide,
    p.status,
    p.highest_similarity_score,
    p.matched_proposal_id,
    p.submitted_at
FROM proposals p
JOIN student_teams t ON p.team_id = t.team_id
JOIN domains d ON p.domain_id = d.domain_id
LEFT JOIN students lead ON lead.team_id = t.team_id AND lead.is_team_lead = 1
LEFT JOIN faculty_guides g ON t.guide_id = g.guide_id;

-- View 3: Domain-wise Analytics & Risk Rates
CREATE VIEW v_domain_analytics AS
SELECT 
    d.domain_id,
    d.domain_name,
    COUNT(p.proposal_id) AS total_proposals,
    SUM(CASE WHEN p.highest_similarity_score >= 80.0 OR p.status = 'Flagged Duplicate' THEN 1 ELSE 0 END) AS flagged_duplicate_count,
    SUM(CASE WHEN p.status = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN p.status = 'Merged Team' THEN 1 ELSE 0 END) AS merged_count,
    ROUND(AVG(p.highest_similarity_score), 2) AS average_similarity_score,
    ROUND((CAST(SUM(CASE WHEN p.highest_similarity_score >= 80.0 THEN 1 ELSE 0 END) AS REAL) / 
          MAX(1, COUNT(p.proposal_id))) * 100.0, 1) AS duplicate_risk_percentage
FROM domains d
LEFT JOIN proposals p ON d.domain_id = p.domain_id
GROUP BY d.domain_id, d.domain_name;

-- View 4: Merged Teams & Entity Resolution Roster
CREATE VIEW v_merged_teams_roster AS
SELECT 
    t.team_id,
    t.team_name,
    t.status AS team_status,
    p.proposal_id,
    p.title AS proposal_title,
    r.review_id,
    r.decision,
    r.remarks AS guide_remarks,
    r.merged_with_proposal_id,
    r.review_timestamp
FROM student_teams t
JOIN proposals p ON p.team_id = t.team_id
LEFT JOIN faculty_reviews r ON r.proposal_id = p.proposal_id
WHERE p.status = 'Merged Team' OR t.status = 'Merged';

-- View 5: System Audit History View
CREATE VIEW v_audit_history AS
SELECT 
    audit_id,
    table_name,
    action_type,
    record_id,
    details,
    performed_by,
    timestamp
FROM system_audit_logs
ORDER BY audit_id DESC;

-- ----------------------------------------------------------------------------
-- 5. DBMS TRIGGERS (ACID AUDIT & STATUS AUTOMATION)
-- ----------------------------------------------------------------------------

-- Trigger 1: Automatically log changes to proposal status
CREATE TRIGGER trg_proposal_status_audit
AFTER UPDATE OF status ON proposals
FOR EACH ROW
WHEN OLD.status <> NEW.status
BEGIN
    INSERT INTO system_audit_logs (table_name, action_type, record_id, details, performed_by)
    VALUES (
        'proposals',
        'STATUS_CHANGE',
        NEW.proposal_id,
        'Proposal status updated from [' || OLD.status || '] to [' || NEW.status || '] (Similarity: ' || NEW.highest_similarity_score || '%)',
        'Faculty Review System'
    );
END;

-- Trigger 2: Automatically log faculty reviews
CREATE TRIGGER trg_faculty_review_audit
AFTER INSERT ON faculty_reviews
FOR EACH ROW
BEGIN
    INSERT INTO system_audit_logs (table_name, action_type, record_id, details, performed_by)
    VALUES (
        'faculty_reviews',
        'REVIEW_DECISION',
        NEW.review_id,
        'Guide ID ' || NEW.guide_id || ' executed decision: ' || NEW.decision || ' for Proposal #' || NEW.proposal_id || '. Remarks: ' || COALESCE(NEW.remarks, 'None'),
        'Dr. S.P. Ramya'
    );
END;

-- Trigger 3: Automatically set duplicate flag when high similarity log is recorded
CREATE TRIGGER trg_similarity_threshold_check
AFTER INSERT ON similarity_logs
FOR EACH ROW
WHEN NEW.final_calibrated_score >= 80.0
BEGIN
    UPDATE proposals 
    SET status = 'Flagged Duplicate',
        highest_similarity_score = MAX(highest_similarity_score, NEW.final_calibrated_score),
        matched_proposal_id = NEW.target_proposal_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE proposal_id = NEW.source_proposal_id;

    INSERT INTO system_audit_logs (table_name, action_type, record_id, details, performed_by)
    VALUES (
        'similarity_logs',
        'HIGH_RISK_FLAG_TRIGGERED',
        NEW.source_proposal_id,
        'Institutional threshold >= 80% triggered! Score: ' || NEW.final_calibrated_score || '% against Proposal #' || NEW.target_proposal_id,
        'Automated AI Detection Engine'
    );
END;

-- ----------------------------------------------------------------------------
-- 6. BENCHMARK SEED DATA (SRMIST AI DEPARTMENT)
-- ----------------------------------------------------------------------------

-- Seed Department
INSERT INTO departments (dept_id, dept_name, institution) 
VALUES ('CSE-AI', 'Department of Artificial Intelligence', 'SRMIST Tiruchirappalli');

-- Seed Faculty Guides
INSERT INTO faculty_guides (guide_id, name, email, dept_id, designation, specialization) 
VALUES (1, 'Dr. S.P. Ramya', 'ramya.sp@ktr.srmist.edu.in', 'CSE-AI', 'Associate Professor & Research Lead', 'Deep Learning & Natural Language Processing');

INSERT INTO faculty_guides (guide_id, name, email, dept_id, designation, specialization) 
VALUES (2, 'Dr. K. Mohan', 'mohan.k@ktr.srmist.edu.in', 'CSE-AI', 'Assistant Professor', 'Computer Vision & Robotics');

-- Seed Domains
INSERT INTO domains (domain_id, domain_name, category, description, coordinator_id) VALUES
(1, 'Artificial Intelligence & Vision', 'Computer Vision', 'Image processing, facial recognition, autonomous surveillance, and video analytics', 1),
(2, 'Healthcare & Deep Learning', 'Medical Diagnostics', 'Medical imaging, ophthalmology fundus scans, oncology MRI, and bio-informatics', 1),
(3, 'Robotics & Autonomous IoT', 'Robotics', 'Autonomous surface vessels, UAVs, environmental trash cleaners, and embedded systems', 2),
(4, 'Blockchain & Cryptography', 'Decentralized Systems', 'Smart contracts, academic credentials verification, decentralized identities, and ledger security', 1),
(5, 'Smart Agriculture & AI', 'Applied AI', 'Crop disease diagnosis, precision farming, UAV multispectral pest surveillance, and yield estimation', 2),
(6, 'Cybersecurity & Networks', 'Security', 'Intrusion detection systems, DDoS mitigation, network traffic anomaly detection, and packet inspection', 1),
(7, 'Software Engineering & Web', 'Software Architecture', 'Full-stack distributed architectures, cloud platforms, and microservices portals', 1);

-- Seed Academic Entity Resolution Concepts
INSERT INTO entity_concepts (concept_id, concept_name, domain_id, core_terms, technical_terms, institutional_risk_weight) VALUES
(1, 'Facial Attendance Tracking', 1, 'attendance,roll call,presence,absenteeism,proxy,classroom,lecture hall', 'face,facial,biometric,opencv,webcam,camera,resnet,haar cascade,embeddings', 1.0),
(2, 'Retinal Eye Disease Diagnosis', 2, 'retina,retinopathy,fundus,ophthalmology,eye disease,blindness,diabetic', 'cnn,deep learning,lesion,microaneurysm,efficientnet,optical coherence,transfer learning', 1.0),
(3, 'Aquatic River Cleaning Drone', 3, 'river,water,waterway,aquatic,marine,lake,floating plastic,trash', 'trash,debris,boat,drone,cleaner,autonomous,gps,yolo,surface craft', 1.0),
(4, 'Blockchain Academic Credentials', 4, 'degree,diploma,certificate,credential,academic,forgery,tamper-proof', 'blockchain,ethereum,smart contract,cryptographic,hash,ipfs,solidity', 1.0),
(5, 'Crop / Plant Leaf Disease Diagnosis', 5, 'crop,leaf,plant,agriculture,farmer,harvest,paddy,tomato', 'disease,blight,fertilizer,vision transformer,fungal,vit,convolutional', 1.0),
(6, 'Network Intrusion Cybersecurity', 6, 'intrusion,cybersecurity,ddos,packet,traffic anomaly,packet inspection', 'random forest,firewall,attack,anomaly detection,ids,wireshark,snort', 1.0),
(7, 'E-Commerce Marketplace', 7, 'shopping,e-commerce,marketplace,store,cart,products,orders', 'inventory,merchant,payment,catalog,checkout,stripe,full stack,react', 0.8),
(8, 'Brain Tumor MRI Segmentation', 2, 'brain,tumor,mri,glioma,meningioma,radiology', 'unet,u-net,segmentation,dicom,deep learning,mask r-cnn', 1.0),
(9, 'Fake News & Misinformation Detector', 1, 'fake news,misinformation,rumor,propaganda,fact check', 'bert,transformer,roberta,nlp,sentiment,lstm,classifier', 0.9);

-- Seed Teams 1-5
INSERT INTO student_teams (team_id, team_name, guide_id, status) VALUES
(1, 'Team Alpha - Vision AI', 1, 'Active'),
(2, 'Team RetinaHealth', 1, 'Active'),
(3, 'Team AquaClean Tech', 2, 'Active'),
(4, 'Team BlockVerify', 1, 'Active'),
(5, 'Team AgriVision', 2, 'Active');

-- Seed Students (Team Leads & Members)
INSERT INTO students (reg_no, full_name, email, team_id, is_team_lead, dept_id, year_of_study) VALUES
('RA2411047050001', 'Aarav Sharma', 'aarav.s@srmist.edu.in', 1, 1, 'CSE-AI', 3),
('RA2411047050002', 'Pooja Iyer', 'pooja.i@srmist.edu.in', 1, 0, 'CSE-AI', 3),
('RA2411047050015', 'Rohan Verma', 'rohan.v@srmist.edu.in', 2, 1, 'CSE-AI', 3),
('RA2411047050016', 'Kavya Nair', 'kavya.n@srmist.edu.in', 2, 0, 'CSE-AI', 3),
('RA2411047050028', 'Deepak Sundaram', 'deepak.s@srmist.edu.in', 3, 1, 'CSE-AI', 3),
('RA2411047050029', 'Ananya Patel', 'ananya.p@srmist.edu.in', 3, 0, 'CSE-AI', 3),
('RA2411047050044', 'Vikramaditya Rao', 'vikram.r@srmist.edu.in', 4, 1, 'CSE-AI', 3),
('RA2411047050045', 'Meera Krishnan', 'meera.k@srmist.edu.in', 4, 0, 'CSE-AI', 3),
('RA2411047050062', 'Siddharth Jain', 'siddharth.j@srmist.edu.in', 5, 1, 'CSE-AI', 3),
('RA2411047050063', 'Divya Balaji', 'divya.b@srmist.edu.in', 5, 0, 'CSE-AI', 3);

-- Seed Benchmark Proposals
INSERT INTO proposals (proposal_id, team_id, domain_id, title, problem_statement, methodology, full_description, status, highest_similarity_score) VALUES
(1, 1, 1, 
 'Smart Attendance System using Face Recognition', 
 'Manual student attendance in large university lecture halls is time-consuming and vulnerable to proxy attendance.', 
 'Contactless automatic recognition deploying deep learning convolutional neural networks and camera streams in lecture halls to identify registered students.', 
 'An automated contactless attendance monitoring solution deploying deep learning convolutional neural networks and camera streams in lecture halls to identify registered students and eliminate proxy attendance.', 
 'Approved', 0.0),

(2, 2, 2, 
 'Deep Learning Based Diabetic Retinopathy Detection', 
 'Early detection of diabetic retinopathy is critical to prevent permanent blindness but requires scarce ophthalmologists.', 
 'Utilizing transfer learning and EfficientNet on retinal fundus photography to detect microaneurysms and classify disease stages.', 
 'An ophthalmology diagnostic aid utilizing transfer learning and EfficientNet on retinal fundus photography to detect microaneurysms and classify diabetic retinopathy severity stages.', 
 'Approved', 0.0),

(3, 3, 3, 
 'Autonomous River Surface Trash Collecting Drone', 
 'Urban rivers and municipal waterways suffer from massive floating plastic debris polluting drinking water.', 
 'Unmanned aquatic robot powered by computer vision object detection and GPS waypoints to detect and scoop floating debris.', 
 'An unmanned aquatic robot powered by computer vision object detection and GPS waypoints to detect and scoop floating plastic debris from urban rivers and municipal waterways.', 
 'Approved', 0.0),

(4, 4, 4, 
 'Decentralized Academic Credential Verification using Ethereum Smart Contracts', 
 'Counterfeit degrees and fake educational certificates compromise recruitment and university credibility.', 
 'A blockchain-anchored certificate issuing and tamper-proof verification architecture with cryptographic signature validation.', 
 'A blockchain-anchored certificate issuing and tamper-proof verification architecture preventing counterfeit university degrees with cryptographic signature validations.', 
 'Approved', 0.0),

(5, 5, 5, 
 'Crop Disease Detection and Fertilizer Recommendation System', 
 'Rural farmers lack real-time plant pathology expertise, leading to extensive crop loss from fungal infections.', 
 'A mobile agricultural assistant that captures smartphone leaf photos, diagnoses fungal or bacterial blights with Vision Transformers, and recommends eco-friendly treatments.', 
 'A mobile agricultural assistant for rural farmers that captures smartphone leaf photos, diagnoses fungal or bacterial blights with Vision Transformers, and recommends eco-friendly treatments.', 
 'Approved', 0.0);

-- Seed Initial System Audit Log
INSERT INTO system_audit_logs (table_name, action_type, record_id, details, performed_by) VALUES
('database', 'INITIAL_MIGRATION', 1, 'SRMIST AI Department 3NF Relational Schema successfully compiled and seeded with 5 benchmark projects.', 'Dr. S.P. Ramya');
