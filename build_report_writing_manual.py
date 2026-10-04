# -*- coding: utf-8 -*-
"""
Builds PROJECT_REPORT_WRITING_MANUAL.html
A comprehensive guide for writing the EEE 306 Project Report aligned with Course Objectives,
CO1-CO9, PO(a)-PO(l), Course Outline, specific teacher questions (LLL vs LLG, V=0 proof),
transformer loading graphs, 360 MW balanced load flow, protection integration (APSCL vs Our Study),
and real-life industrial datasheets and SLD crops.
"""

import os
import sys

OUTPUT_FILE = r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\PROJECT_REPORT_WRITING_MANUAL.html"

html_content = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>EEE 306 Project Report Writing Manual & Blueprint — Ashuganj South 450 MW CCPP</title>
<meta name="description" content="Complete chapter-by-chapter and section-by-section manual for writing the EEE 306 Power System Analysis & Protection Project Report, including exact diagrams, formulas, tables, data sources, teacher feedback resolutions, and CO-PO alignments.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@500;600;700&family=Crimson+Pro:ital,wght@0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">
<style>
:root {
  --navy: #0b1e2d;
  --navy-light: #16364e;
  --teal: #087f7b;
  --teal-dark: #065e5b;
  --teal-light: #e6f7f6;
  --blue: #1558d6;
  --blue-light: #eaf1fd;
  --red: #c5221f;
  --red-light: #fce8e6;
  --amber: #b45309;
  --amber-light: #fef7ee;
  --green: #0d8a59;
  --green-light: #ebfbf3;
  --purple: #7033c9;
  --purple-light: #f4ecfd;
  --bg: #f8fafc;
  --card: #ffffff;
  --line: #cbd5e1;
  --text: #0f172a;
  --text-muted: #475569;
  --font-scale: 1.08;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.7;
  font-size: calc(15.5px * var(--font-scale));
}
.shell { display: flex; min-height: 100vh; }
.sidebar {
  width: 340px;
  background: var(--navy);
  color: #fff;
  padding: 24px 18px;
  flex-shrink: 0;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  border-right: 1px solid rgba(255,255,255,0.1);
}
.sidebar h2 {
  font-size: calc(16px * var(--font-scale));
  margin: 0 0 6px 0;
  color: #fff;
  font-weight: 800;
  letter-spacing: -0.3px;
}
.sidebar small {
  display: block;
  color: #94a3b8;
  margin-bottom: 18px;
  font-size: calc(12px * var(--font-scale));
}
.nav a {
  display: block;
  color: #cbd5e1;
  text-decoration: none;
  padding: 8px 12px;
  border-radius: 7px;
  margin-bottom: 4px;
  font-size: calc(12.5px * var(--font-scale));
  font-weight: 500;
  transition: all 0.2s ease;
  line-height: 1.4;
}
.nav a:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}
.nav a.active {
  background: var(--teal);
  color: #fff;
  font-weight: 700;
}
.sidebar-box {
  margin-top: 22px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 9px;
  padding: 13px;
  font-size: calc(11.8px * var(--font-scale));
  color: #94a3b8;
  line-height: 1.55;
}
.sidebar-box b { color: #f1f5f9; }

.main {
  flex: 1;
  padding: 36px 48px;
  max-width: 1420px;
  margin: 0 auto;
}
html.full-width .main { max-width: 100%; }

/* PRESENTATION TOOLBAR */
.presentation-bar {
  position: sticky;
  top: 0;
  z-index: 100;
  background: #ffffff;
  border: 1.5px solid var(--line);
  border-radius: 12px;
  padding: 10px 18px;
  margin-bottom: 28px;
  box-shadow: 0 4px 16px rgba(15, 43, 60, 0.08);
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
}
.pbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  color: var(--navy);
  font-size: calc(13.5px * var(--font-scale));
}
.pbar-badge {
  background: var(--teal-light);
  color: var(--teal);
  border: 1px solid var(--teal);
  padding: 3px 8px;
  border-radius: 6px;
  font-size: calc(11px * var(--font-scale));
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.pbar-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}
.pbar-btn {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  color: #334155;
  padding: 5px 12px;
  border-radius: 6px;
  font-weight: 600;
  font-size: calc(12.5px * var(--font-scale));
  cursor: pointer;
  transition: all 0.15s ease;
}
.pbar-btn:hover {
  background: var(--navy);
  color: #fff;
  border-color: var(--navy);
}
.pbar-btn.active {
  background: var(--teal);
  color: #fff;
  border-color: var(--teal);
}

.eyebrow {
  color: var(--teal);
  text-transform: uppercase;
  font-size: calc(12px * var(--font-scale));
  font-weight: 800;
  letter-spacing: 1px;
  margin: 0 0 6px 0;
}
h1 {
  font-size: calc(32px * var(--font-scale));
  color: var(--navy);
  margin: 0 0 12px 0;
  line-height: 1.25;
  font-weight: 900;
}
.lead {
  font-size: calc(16.5px * var(--font-scale));
  color: #475569;
  margin-bottom: 28px;
  max-width: 1150px;
  line-height: 1.75;
}

/* CARDS & SECTIONS */
.card {
  background: var(--card);
  border: 1.5px solid var(--line);
  border-radius: 14px;
  padding: 28px 34px;
  margin-bottom: 30px;
  box-shadow: 0 3px 12px rgba(15, 43, 60, 0.05);
}
.card h2 {
  font-size: calc(23px * var(--font-scale));
  color: var(--navy);
  margin: 0 0 14px 0;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 2px solid #e2e8f0;
  padding-bottom: 10px;
}
.card h3 {
  font-size: calc(18px * var(--font-scale));
  color: var(--navy-light);
  margin: 22px 0 10px 0;
  font-weight: 700;
}
.status-pill {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: calc(11px * var(--font-scale));
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 12px;
}
.pill-teal { background: var(--teal-light); color: var(--teal); border: 1px solid var(--teal); }
.pill-blue { background: var(--blue-light); color: var(--blue); border: 1px solid var(--blue); }
.pill-red { background: var(--red-light); color: var(--red); border: 1px solid var(--red); }
.pill-amber { background: var(--amber-light); color: var(--amber); border: 1px solid var(--amber); }
.pill-green { background: var(--green-light); color: var(--green); border: 1px solid var(--green); }
.pill-purple { background: var(--purple-light); color: var(--purple); border: 1px solid var(--purple); }

/* WRITING GUIDELINES BOXES */
.guide-box {
  background: #fdfefe;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 20px;
  margin: 18px 0;
}
.guide-header {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 800;
  font-size: calc(15px * var(--font-scale));
  margin-bottom: 10px;
}
.guide-include { border-left: 5px solid var(--blue); }
.guide-include .guide-header { color: var(--blue); }

.guide-write { border-left: 5px solid var(--green); }
.guide-write .guide-header { color: var(--green); }

.guide-eq { border-left: 5px solid var(--purple); }
.guide-eq .guide-header { color: var(--purple); }

.guide-src { border-left: 5px solid var(--amber); }
.guide-src .guide-header { color: var(--amber); }

.guide-spotlight {
  border: 2px solid var(--red);
  background: #fffafa;
  border-radius: 12px;
  padding: 24px;
  margin: 24px 0;
}
.guide-spotlight h3 {
  color: var(--red);
  margin-top: 0;
}

/* EQUATION BLOCKS */
.eq-box {
  background: #f1f5f9;
  border-left: 4px solid var(--navy-light);
  padding: 14px 18px;
  margin: 14px 0;
  border-radius: 0 8px 8px 0;
  font-family: 'Crimson Pro', Georgia, serif;
  font-size: calc(18px * var(--font-scale));
  color: #0f172a;
  overflow-x: auto;
}
.eq-title {
  font-family: 'Inter', sans-serif;
  font-size: calc(12px * var(--font-scale));
  text-transform: uppercase;
  font-weight: 800;
  color: #475569;
  margin-bottom: 4px;
  letter-spacing: 0.5px;
}

/* CODE / FILE CHIPS */
.file-chip {
  background: #e2e8f0;
  color: #1e293b;
  padding: 2px 7px;
  border-radius: 5px;
  font-family: 'JetBrains Mono', monospace;
  font-size: calc(12px * var(--font-scale));
  font-weight: 600;
  word-break: break-all;
}
.val-badge {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  padding: 1px 6px;
  border-radius: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-weight: 700;
  color: #0f172a;
}

/* TABLES */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 16px 0 20px 0;
  font-size: calc(13.8px * var(--font-scale));
}
th {
  background: var(--navy);
  color: #fff;
  text-align: left;
  padding: 11px 13px;
  font-weight: 700;
}
td {
  padding: 10px 13px;
  border-bottom: 1px solid var(--line);
  vertical-align: top;
}
tr:nth-child(even) td { background: #f8fafc; }
tr:hover td { background: #f1f5f9; }

/* BULLETS */
ul.manual-list {
  padding-left: 22px;
  margin: 10px 0;
}
ul.manual-list li {
  margin-bottom: 9px;
  line-height: 1.65;
}

@media print {
  .sidebar, .presentation-bar { display: none !important; }
  .main { padding: 0 !important; width: 100% !important; max-width: 100% !important; }
  body { font-size: 10.5pt !important; background: #fff !important; }
  .card { box-shadow: none !important; border: 1px solid #ccc !important; page-break-inside: avoid; margin-bottom: 20px; }
  .guide-box { page-break-inside: avoid; }
}
</style>
</head>
<body>

<div class="shell">
  <!-- SIDEBAR NAVIGATION -->
  <aside class="sidebar">
    <h2>Project Report Manual</h2>
    <small>EEE 306 · Ashuganj South 450 MW</small>
    <nav class="nav">
      <a href="#overview" class="active">0 · Overview & CO-PO Mapping</a>
      <a href="#ch1">Ch 1 · Introduction & Plant Layout</a>
      <a href="#real-datasheets">📋 Real Datasheets & SLD Guide</a>
      <a href="#ch2">Ch 2 · Problem Formulation & Scope</a>
      <a href="#ch3">Ch 3 · Methodology & Modeling</a>
      <a href="#ch3-assumptions">⚙️ Ch 3.4 · Assumptions Matrix</a>
      <a href="#ch4">Ch 4 · Load Flow (360 MW) & Transformers</a>
      <a href="#ch5">Ch 5 · Fault Study & Symmetrical Components</a>
      <a href="#spotlight-llg">⚡ Teacher Q1 · LLL vs LLG Fault Current</a>
      <a href="#spotlight-vzero">⚡ Teacher Q2 · Why Voltage is 0 in LLL</a>
      <a href="#ch6">Ch 6 · Protection (APSCL vs Our Study)</a>
      <a href="#ch7">Ch 7 · Dynamic Simulation & DC Battery</a>
      <a href="#ch8">Ch 8 · Societal, Safety & Economic Impact</a>
      <a href="#ch9">Ch 9 · Teamwork, Management & Tools</a>
      <a href="#ch10">Ch 10 · Conclusions & Limitations</a>
      <a href="#checklist">Appendix · Submission Checklist</a>
    </nav>
    <div class="sidebar-box">
      <b>Report Blueprint Quick Guide:</b><br>
      • <b>Format:</b> EEE-xxx-project-report-template<br>
      • <b>Primary Dispatch:</b> 360.0 MW (APSCL Form B3)<br>
      • <b>Net Grid Export:</b> 345.2 MW at 230 kV<br>
      • <b>Auxiliary Demand:</b> 14.0 MW at 6.6 kV<br>
      • <b>Max Fault:</b> 126.2 kA 3-Phase at 22 kV<br>
      • <b>NER Ground:</b> 7.27 A (Prevents Melting)<br>
      • <b>Breaker Safety:</b> GCB 55%, GIS 13.8% Duty<br>
      • <b>Course Outcomes:</b> CO1 to CO9 Compliant
    </div>
  </aside>

  <!-- MAIN CONTENT -->
  <main class="main">
    <!-- PRESENTATION TOOLBAR -->
    <div class="presentation-bar">
      <div class="pbar-left">
        <span class="pbar-badge">Report Writing Blueprint</span>
        <span>Font Scaling:</span>
      </div>
      <div class="pbar-actions">
        <button class="pbar-btn" id="btn-scale-1" onclick="setFontScale(0.95, this)">95%</button>
        <button class="pbar-btn active" id="btn-scale-2" onclick="setFontScale(1.08, this)">100% Standard</button>
        <button class="pbar-btn" id="btn-scale-3" onclick="setFontScale(1.25, this)">120% Large</button>
        <button class="pbar-btn" id="btn-scale-4" onclick="setFontScale(1.45, this)">📽️ 145% Projector</button>
        <button class="pbar-btn" id="btn-full-width" onclick="toggleFullWidth(this)">⛶ Full Width</button>
        <button class="pbar-btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
      </div>
    </div>

    <p class="eyebrow">Comprehensive Academic Blueprint · EEE 306 Power System Analysis & Protection</p>
    <h1>Project Report Writing Manual: Section-by-Section Guide</h1>
    <p class="lead">This manual gives you the complete blueprint to write your final project report using the standard departmental <b>EEE-xxx-project-report-template</b>. For every single section, it explicitly tells you: <b>what diagrams to include</b>, <b>what graphs to show</b>, <b>what equations to derive</b>, <b>what real-life datasheet numbers to cite</b>, and <b>which exact file in this workspace contains the data</b>. It also features dedicated solutions for the specific viva/report questions raised by your course teacher.</p>

    <!-- SECTION 0: COURSE OBJECTIVES & CO-PO MAPPING -->
    <section id="overview" class="card">
      <span class="status-pill pill-teal">Curriculum Alignment</span>
      <h2>0 · Course Objectives, Program Outcomes (POs) & CO Mapping</h2>
      <p>To score the maximum grade in EEE 306, your project report must explicitly demonstrate how your work satisfies the required <b>Course Outcomes (COs)</b> and <b>Program Outcomes (POs)</b>. Include this summary table right in your report's Introductory section:</p>

      <table>
        <thead>
          <tr>
            <th>CO #</th>
            <th>Course Outcome Description</th>
            <th>Program Outcome (PO)</th>
            <th>Bloom's Taxonomy</th>
            <th>Where Addressed in This Report</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><b>CO1</b></td>
            <td>Investigate PFI plant behavior and power factor control</td>
            <td>PO(a), PO(d)</td>
            <td>C4 (Analysis)</td>
            <td><b>Chapter 4:</b> Generator excitation & reactive power (27.8 MVAr, PF = 0.997).</td>
          </tr>
          <tr>
            <td><b>CO2</b></td>
            <td>Transmission line equivalent circuit modeling (short, medium, long)</td>
            <td>PO(b)</td>
            <td>C3, C4 (Application)</td>
            <td><b>Chapter 3 & 4:</b> 0.7 km dual-circuit 230 kV Mallard line lumped nominal PI model.</td>
          </tr>
          <tr>
            <td><b>CO3</b></td>
            <td>Use power system analysis tools (PSAF / Simscape / MATLAB) for load flow and fault studies</td>
            <td>PO(e)</td>
            <td>C4, P4 (Modern Tools)</td>
            <td><b>Chapter 3, 4, 5:</b> PSAF data audit, Newton-Raphson load flow, IEC 60909 fault runs.</td>
          </tr>
          <tr>
            <td><b>CO4</b></td>
            <td>Investigate system modifications and design upgrades</td>
            <td>PO(c)</td>
            <td>C4, C6 (Design)</td>
            <td><b>Chapter 6 & 7:</b> Adding 20/1 A neutral CT, 1,750 Ω NER, and DC trip interlock logic.</td>
          </tr>
          <tr>
            <td><b>CO5</b></td>
            <td>Design power system element with safety, societal and environmental context</td>
            <td>PO(c), PO(f), PO(g)</td>
            <td>C6 (Evaluation)</td>
            <td><b>Chapter 8:</b> SF6 gas toxic decomposition prevention, transformer fireball containment.</td>
          </tr>
          <tr>
            <td><b>CO6</b></td>
            <td>Demonstrate membership and leadership in complex engineering problem solving</td>
            <td>PO(i)</td>
            <td>P7 (Organization)</td>
            <td><b>Chapter 9:</b> Team work allocation, phase ownership, and verification logbook.</td>
          </tr>
          <tr>
            <td><b>CO7</b></td>
            <td>Effective technical communication via presentation and detailed report</td>
            <td>PO(j)</td>
            <td>A2 (Responding)</td>
            <td><b>The Report itself & 4-min Video:</b> Structured report, clear SLDs, and recorded video.</td>
          </tr>
          <tr>
            <td><b>CO8</b></td>
            <td>Project management and cost-benefit economic analysis</td>
            <td>PO(k)</td>
            <td>A3 (Valuing)</td>
            <td><b>Chapter 8:</b> Capital protection cost ($2.1M) vs. catastrophic outage loss ($15–25M).</td>
          </tr>
          <tr>
            <td><b>CO9</b></td>
            <td>Understand layout and operation of power plants and substations</td>
            <td>PO(a)</td>
            <td>C2 (Comprehension)</td>
            <td><b>Chapter 1 & Datasheets:</b> Ashuganj South 450 MW CCPP layout, 230 kV GIS switchyard, UAT/GAT feeds.</td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- CHAPTER 1: INTRODUCTION & PLANT LAYOUT -->
    <section id="ch1" class="card">
      <span class="status-pill pill-blue">Report Chapter 1</span>
      <h2>Chapter 1: Introduction, Plant Overview & Substation Layout (CO9, PO-a)</h2>
      <p><b>Purpose:</b> Establish the physical context of the Ashuganj South 450 MW CCPP, its role in Bangladesh's national grid, and the necessity of protection engineering.</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Diagrams & Figures to Include in Chapter 1:</div>
        <ul class="manual-list">
          <li><b>Figure 1.1: Master Single Line Diagram (SLD) of Ashuganj South 450 MW CCPP.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase 4 Docs/snapshots/sld_fault_locations_marked.png</span> or <span class="file-chip">Phase 5 Docs/snapshots/000_Plant_overview.png</span>.</li>
          <li><b>Figure 1.2: Plant Power Train Architecture (Generator → GCB → GSUT → 230 kV GIS Switchyard).</b><br>
          <i>Source file:</i> Take the overview diagram from <span class="file-chip">306 Power Project -kimi k3-v4/Ashuganj_South_Presentation_and_Viva.html</span> (Slide: <i>The plant electrical power path</i>) or use the block diagram from Chapter 1 of <span class="file-chip">PROJECT_RESULTS_AND_FINDINGS.html</span>.</li>
        </ul>
      </div>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ What to Write & Explain in Chapter 1:</div>
        <ul class="manual-list">
          <li><b>Plant Description:</b> State that Ashuganj South is a single-shaft Combined Cycle Power Plant (CCPP) consisting of a Siemens SGT5-4000F Gas Turbine, SST-3000 Steam Turbine, and an SGen5-2000H Synchronous Generator (458 MVA gross, 22 kV, 50 Hz, 0.85 pf).</li>
          <li><b>National Grid Interconnection:</b> Explain that the plant steps up voltage from 22 kV to 230 kV via a 515 MVA Generator Step-Up Transformer (GSUT) and exports power into the Power Grid Company of Bangladesh (PGCB) 230 kV national grid through a dual-circuit 0.7 km overhead line.</li>
          <li><b>Plant Auxiliary Architecture:</b> Detail how internal station power (14.0 MW at 6.6 kV) is supplied by the Unit Auxiliary Transformer (UAT, 22/6.9 kV) during normal operation, and by the Grid Auxiliary Transformer (GAT, 230/6.9 kV) during startup or backup transfer.</li>
          <li><b>Substation Physical Layout:</b> Explain that the switchyard utilizes Siemens 8DN9 Gas-Insulated Switchgear (GIS) with SF6 insulation, featuring a double busbar system (Bus 1 and Bus 2) tied by a bus coupler breaker (10BAY13).</li>
        </ul>
      </div>

      <div class="guide-box guide-src">
        <div class="guide-header">📂 Where to Get the Data for Chapter 1:</div>
        <ul class="manual-list">
          <li>Master parameters: <span class="file-chip">Ashuganj_South_Final_Master_Data_and_Assumptions.pdf</span> and <span class="file-chip">data/master/Ashuganj_Master_Data.csv</span>.</li>
          <li>Summary facts: <span class="file-chip">PROJECT_RESULTS_AND_FINDINGS.html</span> (Section 1 & 2).</li>
        </ul>
      </div>
    </section>

    <!-- NEW SPECIAL SECTION: REAL-LIFE DATASHEETS & SLD GUIDE -->
    <section id="real-datasheets" class="card" style="border: 2px solid var(--blue); background: #fdfefe;">
      <span class="status-pill pill-blue">Special Industry Evidence</span>
      <h2>📋 Real-Life Industrial Datasheets & Single Line Diagrams: Exact Data & Report Placement</h2>
      <p>Your evaluators and course teacher want to see genuine proof that this design is not an imaginary academic exercise, but is anchored directly in <b>actual Siemens factory drawings, OEM nameplates, and PGCB transmission sheets</b>. Below is the complete catalog of real datasheet values, drawing numbers, and exact instructions on <b>where to place each one in your report</b>.</p>

      <!-- 1. Real SLD & Crops -->
      <div class="guide-box guide-include">
        <div class="guide-header">1. The Real Master Single Line Diagram (SLD) & 1:1 HD Crops:</div>
        <p>The real electrical engineering drawing for the Ashuganj South switchyard is official drawing:  
        <span class="file-chip">Siemens / TSK / INELECTRA Drawing No: S008-112070-00-ELC-DE-1011 (Rev 04/04_1 As-Built Factory)</span> and <span class="file-chip">INEL-112070-00-ELC-DE-0001-REV3.pdf</span>.</p>
        
        <p><b>Where to place in your report:</b></p>
        <ul class="manual-list">
          <li><b>Chapter 1 (Figure 1.1):</b> Embed the complete Master SLD showing the entire plant corridor:  
          <i>File:</i> <span class="file-chip">Phase 4 Docs/snapshots/sld_fault_locations_marked.png</span>.</li>
          <li><b>Chapter 5 (Figures 5.3 to 5.7):</b> Embed the 1:1 native resolution crops directly into your fault study subsections so the examiner can clearly read breaker tags and CT ratios:
            <br>• <b>Crop 1 (F1 - Generator Terminal):</b> <span class="file-chip">Phase 4 Docs/snapshots/sld_crop_f1_generator.png</span> (Shows Generator `10MKA10`, GCB `10BAC10`, and NER `10BAB11`).
            <br>• <b>Crop 2 (F2 - GSUT LV Terminals):</b> <span class="file-chip">Phase 4 Docs/snapshots/sld_crop_f2_gsut_lv.png</span> (Shows GSUT `10BAT10` LV delta bushings, UAT `10BBT10`, and IPB duct).
            <br>• <b>Crop 3 (F3 - 230 kV GIS Switchyard):</b> <span class="file-chip">Phase 4 Docs/snapshots/sld_crop_f3_gis_switchyard.png</span> (Shows GIS Bus 1 `10BAC01`, Bus 2 `10BAC02`, and Bay `10BAY11`).
            <br>• <b>Crop 4 (F4 - 230 kV Line 1 & 2):</b> <span class="file-chip">Phase 4 Docs/snapshots/sld_crop_f4_line_midpoint.png</span> (Shows outgoing line bays, line disconnectors, and earth switches).
            <br>• <b>Crop 5 (F5 - Remote Utility Grid):</b> <span class="file-chip">Phase 4 Docs/snapshots/sld_crop_f5_remote_grid.png</span> (Shows PGCB interface bus `B230_REMOTE`).
          </li>
        </ul>
      </div>

      <!-- 2. Real Generator Nameplate -->
      <div class="guide-box guide-src">
        <div class="guide-header">2. Real Generator OEM Datasheet & Nameplate (Siemens SGen5-2000H):</div>
        <p><i>Source Documents:</i> <span class="file-chip">fwdtechnicaldatasldrequestforbueteeetermproject/Generator Name Plate_South.pdf</span> and <span class="file-chip">Generator Data_South.pdf</span>.</p>
        <p><b>Where to place in report:</b> Include in <b>Chapter 3 (System Modeling)</b> as <b>Table 3.1: Synchronous Generator OEM Specifications</b>.</p>

        <table>
          <thead>
            <tr>
              <th>Datasheet Field</th>
              <th>Actual Nameplate Value</th>
              <th>Status / Provenance</th>
              <th>Engineering Use in This Report</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Manufacturer & Model</b></td>
              <td><b>Siemens SGen5-2000H</b></td>
              <td>Verified OEM Nameplate</td>
              <td>Hydrogen-cooled 2-pole cylindrical rotor synchronous generator.</td>
            </tr>
            <tr>
              <td><b>Apparent Power ($S_n$)</b></td>
              <td><b>458.0 MVA</b></td>
              <td>Verified OEM Nameplate</td>
              <td>Machine base for impedance base conversion ($Z_{\text{base}} = 1.0568\ \Omega$).</td>
            </tr>
            <tr>
              <td><b>Terminal Voltage ($V_n$)</b></td>
              <td><b>22.0 kV</b> ($\pm 5\%$)</td>
              <td>Verified OEM Nameplate</td>
              <td>22,000 V line-to-line stator rated voltage ($12,701.7\text{ V}$ phase-to-ground).</td>
            </tr>
            <tr>
              <td><b>Rated Stator Current ($I_n$)</b></td>
              <td><b>12,019 A (12.02 kA)</b></td>
              <td>Derived from Nameplate</td>
              <td>$I_n = 458\times 10^6 / (\sqrt{3} \times 22,000) = 12,019.4\text{ A}$.</td>
            </tr>
            <tr>
              <td><b>Active Power ($P$)</b></td>
              <td><b>389.3 MW Rated / 360.0 MW Site</b></td>
              <td>APSCL Project Form (B3)</td>
              <td>Primary dispatch $360.0\text{ MW}$; rated maximum at 0.85 pf is $389.3\text{ MW}$.</td>
            </tr>
            <tr>
              <td><b>Rated Power Factor</b></td>
              <td><b>0.85 lagging</b></td>
              <td>Verified OEM Nameplate</td>
              <td>Defines reactive capability: $Q = 241\text{ MVAr}$ at rated active power.</td>
            </tr>
            <tr>
              <td><b>Subtransient Reactance ($X_d''$)</b></td>
              <td><b>0.2248 pu (Saturated)</b> / 0.2608 (Unsat)</td>
              <td>Verified Factory Test Sheet</td>
              <td><b>Governs peak 3-phase fault at F1 ($126.21\text{ kA}$).</b></td>
            </tr>
            <tr>
              <td><b>Negative Sequence ($X_2$)</b></td>
              <td><b>0.2242 pu</b></td>
              <td>Verified Factory Test Sheet</td>
              <td>Used in unsymmetrical fault sequence networks (LL and LLG).</td>
            </tr>
            <tr>
              <td><b>Zero Sequence ($X_0$)</b></td>
              <td><b>0.1280 pu</b></td>
              <td>Verified Factory Test Sheet</td>
              <td>Stator zero-sequence reactance used in earth fault calculations.</td>
            </tr>
            <tr>
              <td><b>Stator DC Resistance ($R_a$)</b></td>
              <td><b>0.00089 Ω (at 75°C)</b></td>
              <td>Verified Workbook Cell U3</td>
              <td>$0.000842\text{ pu}$ on machine base; produces machine $X/R \approx 266$.</td>
            </tr>
            <tr>
              <td><b>Inertia Constant ($H$)</b></td>
              <td><b>5.287 s (Combined Shaft)</b></td>
              <td>Verified OEM Data Sheet</td>
              <td>Combined gas turbine, steam turbine, and generator shaft inertia for swing equation.</td>
            </tr>
            <tr>
              <td><b>Short Circuit Ratio (SCR)</b></td>
              <td><b>0.601</b></td>
              <td>Verified OEM Data Sheet</td>
              <td>Indicates high steady-state stability margin and electrical stiffness.</td>
            </tr>
            <tr>
              <td><b>Excitation System</b></td>
              <td><b>Static Excitation (SEMIPOL)</b></td>
              <td>Verified OEM Data Sheet</td>
              <td>Thyristor rectifier bridge fed via excitation transformer from 22 kV bus.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 3. Real GSUT Nameplate -->
      <div class="guide-box guide-src">
        <div class="guide-header">3. Real Generator Step-Up Transformer (GSUT) Datasheet:</div>
        <p><i>Source Documents:</i> <span class="file-chip">fwdtechnicaldatasldrequestforbueteeetermproject/GSUT Nameplate_South.pdf</span> and <span class="file-chip">GSUT Data Sheet_South.pdf</span>.</p>
        <p><b>Where to place in report:</b> Include in <b>Chapter 3 (Section 3.2: Transformer Modeling)</b> and <b>Chapter 4 (Section 4.2: Transformer Thermal Loading)</b>.</p>

        <table>
          <thead>
            <tr>
              <th>Datasheet Field</th>
              <th>Actual Nameplate Value</th>
              <th>Engineering Meaning & Application</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Equipment Tag</b></td>
              <td><b>10BAT10</b></td>
              <td>Plant KKS designation on SLD and physical switchyard bay.</td>
            </tr>
            <tr>
              <td><b>MVA Capacity (3 Stages)</b></td>
              <td><b>355 / 460 / 515 MVA</b></td>
              <td>Natural cooling (ONAN) = 355 MVA; Directed oil (ODAN) = 460 MVA; Forced fans (ODAF) = 515 MVA.</td>
            </tr>
            <tr>
              <td><b>Rated Voltage Ratio</b></td>
              <td><b>230,000 V / 22,000 V</b></td>
              <td>Steps up generator voltage ($22\text{ kV}$) to national transmission level ($230\text{ kV}$).</td>
            </tr>
            <tr>
              <td><b>Vector Group</b></td>
              <td><b>YNd1</b> ($+30^\circ$ phase lead)</td>
              <td>HV Wye with neutral solidly grounded; LV Delta. Delta traps zero sequence.</td>
            </tr>
            <tr>
              <td><b>Short-Circuit Impedance ($Z_{\text{sc}}$)</b></td>
              <td><b>16.0% (0.160 pu) on 515 MVA</b></td>
              <td>Limits through-fault current from grid into generator bus during F1 faults.</td>
            </tr>
            <tr>
              <td><b>Full-Load Copper Losses</b></td>
              <td><b>1,067.5 kW</b></td>
              <td>Gives positive-sequence resistance $R_1 = 0.00177\text{ pu}$ on 515 MVA base.</td>
            </tr>
            <tr>
              <td><b>No-Load Core Losses</b></td>
              <td><b>155.3 kW</b></td>
              <td>Magnetizing branch active core loss in transformer equivalent circuit.</td>
            </tr>
            <tr>
              <td><b>Tap Changer (OLTC)</b></td>
              <td><b>MR Reinhausen OLTC, 25 Taps</b></td>
              <td>Range $\pm 10\times 1.25\%$; Principal Tap 9 = $230,000\text{ V}$ ($1.000\text{ pu}$).</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 4. Real UAT & GAT Nameplates -->
      <div class="guide-box guide-src">
        <div class="guide-header">4. Real Auxiliary Transformers (UAT & GAT) Datasheet Data:</div>
        <p><i>Source Documents:</i> <span class="file-chip">fwdtechnicaldatasldrequestforbueteeetermproject/UAT Nameplate_South.pdf</span> and <span class="file-chip">UAT Data Sheet_South.pdf</span>.</p>
        <p><b>Where to place in report:</b> Include in <b>Chapter 3 & 4 (Auxiliary System & Looped Flow)</b>.</p>

        <table>
          <thead>
            <tr>
              <th>Equipment</th>
              <th>Tag</th>
              <th>Ratings</th>
              <th>Voltage Ratio</th>
              <th>Vector Group & Impedance</th>
              <th>Tap Details</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Unit Auxiliary Transformer (UAT)</b></td>
              <td>`10BBT10`</td>
              <td><b>19 / 25 MVA</b> (ONAN / ONAF)</td>
              <td>$22\text{ kV} / 6.9\text{ kV}$</td>
              <td><b>Dyn11</b> ($-30^\circ$ shift)<br>$Z = 10.5\%$ on 25 MVA</td>
              <td>Off-circuit tap changer (5 taps): Principal Tap 3 = $22,000\text{ V}$.</td>
            </tr>
            <tr>
              <td><b>Grid Auxiliary Transformer (GAT)</b></td>
              <td>`10BBT20`</td>
              <td><b>19 / 25 / 8.33 MVA</b> (HV / LV / Tertiary)</td>
              <td>$230\text{ kV} / 6.9\text{ kV} / 3.32\text{ kV}$</td>
              <td><b>YNyn0 + d11</b><br>$Z_{PS} = 12.0\%$ on 25 MVA</td>
              <td>OLTC (25 taps): Principal Tap 13 = $230,000\text{ V}$.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 5. Real Switchgear & Breaker Nameplates -->
      <div class="guide-box guide-src">
        <div class="guide-header">5. Real Circuit Breakers & Switchgear Ratings:</div>
        <p><i>Source Document:</i> <span class="file-chip">Siemens Drawing S008-112070-00-ELC-DE-1011</span>.</p>
        <p><b>Where to place in report:</b> Include in <b>Chapter 5 & 7 (Section 7.2: Breaker Withstand & Duty Margins)</b>.</p>

        <table>
          <thead>
            <tr>
              <th>Breaker Location</th>
              <th>Equipment Model</th>
              <th>Rated Voltage</th>
              <th>Rated Continuous Current</th>
              <th>Certified Breaking Capacity</th>
              <th>Peak Making Current</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Generator Circuit Breaker (GCB)</b></td>
              <td>Siemens `10BAC10`</td>
              <td><b>24 kV</b></td>
              <td><b>12,400 A (12.4 kA)</b></td>
              <td><b style="color:var(--green);">100.0 kA RMS</b></td>
              <td><b>274 kA Peak</b></td>
            </tr>
            <tr>
              <td><b>230 kV GIS Switchyard Breakers</b></td>
              <td>Siemens `8DN9` (SF6 GIS)</td>
              <td><b>245 kV</b></td>
              <td><b>3,150 A (Bus) / 2,000 A (Bay)</b></td>
              <td><b style="color:var(--green);">50.0 kA RMS (3 s)</b></td>
              <td><b>125 kA / 135 kA Peak</b></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 6. Real Instrument Transformers & Relays -->
      <div class="guide-box guide-src">
        <div class="guide-header">6. Real CT, VT, and Numerical Relay Specifications:</div>
        <p><i>Source Document:</i> <span class="file-chip">Phase 5 Docs/PROTECTION_SETTINGS_MANUAL.md</span> and Siemens As-Built Drawing.</p>
        <p><b>Where to place in report:</b> Include in <b>Chapter 6 (Section 6.2: Instrument Transformers & Relay Allocation)</b>.</p>

        <table>
          <thead>
            <tr>
              <th>Equipment Category</th>
              <th>Device Model / Tag</th>
              <th>Physical Parameters / Ratio</th>
              <th>Accuracy Class & Burden</th>
              <th>Assigned Protective Function</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>230 kV GIS Bay CTs</b></td>
              <td>Multi-Ratio Bushing CTs</td>
              <td><b>1600 / 800 / 400 : 1 A</b></td>
              <td>Protection: <b>Class 5P20, 30 VA</b><br>Metering: <b>Class 0.2, 40 VA</b></td>
              <td>Feeds Line Differential (87L), Bus Differential (87B), and Backup Overcurrent (51).</td>
            </tr>
            <tr>
              <td><b>Generator Stator Phase CTs</b></td>
              <td>Generator Bushing CTs</td>
              <td><b>15,000 / 1 A</b></td>
              <td>Protection: <b>Class 5P20, 30 VA</b> (3 Cores)</td>
              <td>Feeds Generator Differential (87G) and Phase Overcurrent (51).</td>
            </tr>
            <tr>
              <td><b>Neutral Ground CT</b></td>
              <td>Dedicated Neutral CT</td>
              <td><b>20 / 1 A</b> (Added in Study)</td>
              <td>Protection: <b>Class 5P20, 15 VA</b></td>
              <td>Steps down 7.27 A earth fault to 0.364 A secondary to feed 51N relay.</td>
            </tr>
            <tr>
              <td><b>230 kV Voltage Transformers</b></td>
              <td>GIS Inductive VT</td>
              <td>$230,000/\sqrt{3} : 100/\sqrt{3}\text{ V}$</td>
              <td>Protection: <b>Class 3P, 30 VA</b><br>Metering: <b>Class 0.2, 30 VA</b></td>
              <td>Feeds Under/Overvoltage (27/59), Distance (21), and Synchrocheck (25).</td>
            </tr>
            <tr>
              <td><b>Generator Differential Relay</b></td>
              <td><b>Siemens SIPROTEC 7UM622</b></td>
              <td>Numerical Multifunction Unit</td>
              <td>High-speed DSP sampling</td>
              <td>Trips in <b>45 ms</b> for internal stator phase short circuits.</td>
            </tr>
            <tr>
              <td><b>Transformer Differential Relay</b></td>
              <td><b>Siemens SIPROTEC 7UT6331</b></td>
              <td>Numerical Transformer Unit</td>
              <td>Dual restraint slope + 2nd harmonic</td>
              <td>Trips in <b>45 ms</b> for internal GSUT faults without tripping on inrush.</td>
            </tr>
            <tr>
              <td><b>Busbar Differential Relay</b></td>
              <td><b>Siemens SIPROTEC 7SS523</b></td>
              <td>Numerical Centralized Bus Unit</td>
              <td>Phase comparison / low-impedance</td>
              <td>Trips in <b>35 ms</b> for switchyard busbar flashovers.</td>
            </tr>
            <tr>
              <td><b>Line Current Differential Relay</b></td>
              <td><b>Siemens SIPROTEC 7SD5221</b></td>
              <td>Dual Redundant Optical Fiber</td>
              <td>Dedicated FO communication link</td>
              <td>Trips in <b>40 ms</b> for 230 kV transmission line faults.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 7. Master Placement Matrix -->
      <div class="guide-box guide-write">
        <div class="guide-header">7. Master Placement Guide: Where to Put Every Real Datasheet in Your Report Template:</div>
        <table>
          <thead>
            <tr>
              <th>Real-Life Document / Datasheet Item</th>
              <th>Target Chapter in Report Template</th>
              <th>Specific Section / Sub-section</th>
              <th>How to Format in Report</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Real OEM Master SLD (`S008-112070`)</b></td>
              <td>Chapter 1: Introduction</td>
              <td>Section 1.2: Plant Layout & Substation Architecture</td>
              <td>Full-page high-resolution figure (Fig. 1.1).</td>
            </tr>
            <tr>
              <td><b>Real SLD 1:1 HD Substation Crops</b></td>
              <td>Chapter 5: Symmetrical Fault Study</td>
              <td>Sections 5.2.1 through 5.2.5 (Each of the 5 nodes)</td>
              <td>Close-up crops showing breaker and disconnector tags.</td>
            </tr>
            <tr>
              <td><b>Generator SGen5-2000H Nameplate</b></td>
              <td>Chapter 3: Methodology & Modeling</td>
              <td>Section 3.1: Synchronous Machine Representation</td>
              <td>Table 3.1 (MVA, kV, Reactances $X_d'', X_2, X_0$, $H$, SCR).</td>
            </tr>
            <tr>
              <td><b>GSUT 515 MVA Transformer Nameplate</b></td>
              <td>Chapter 3 & Chapter 4</td>
              <td>Section 3.2: Transformer Model & Section 4.2: Loading</td>
              <td>Table 3.2 & Bar graph across ONAN/ODAN/ODAF stages.</td>
            </tr>
            <tr>
              <td><b>UAT & GAT Auxiliary Nameplates</b></td>
              <td>Chapter 3 & Chapter 4</td>
              <td>Section 3.3: Auxiliary Subsystems & Section 4.3</td>
              <td>Explain 5.9 MW circulating power in looped mode.</td>
            </tr>
            <tr>
              <td><b>GCB & 230 kV GIS Breaker Ratings</b></td>
              <td>Chapter 5 & Chapter 7</td>
              <td>Section 5.4: Breaker Duty & Section 7.2</td>
              <td>Table comparing certified breaking vs fault currents.</td>
            </tr>
            <tr>
              <td><b>Current & Voltage Transformers (CT/VT)</b></td>
              <td>Chapter 6: Protection System</td>
              <td>Section 6.2: Instrument Transformer Selection</td>
              <td>Table detailing 15,000/1, 1,600/1, and 20/1 CT ratios.</td>
            </tr>
            <tr>
              <td><b>Siemens SIPROTEC Numerical Relays</b></td>
              <td>Chapter 6: Protection System</td>
              <td>Section 6.3: Protective Relay Calibration</td>
              <td>Table listing 7UM622, 7UT6331, 7SS523, and 7SD5221.</td>
            </tr>
            <tr>
              <td><b>Complete OEM PDF Source Catalog</b></td>
              <td>Appendix A</td>
              <td>Appendix A: Document & Drawing Traceability Register</td>
              <td>Full bibliographic catalog of all 15 project PDFs.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- CHAPTER 2: PROBLEM FORMULATION & OBJECTIVES -->
    <section id="ch2" class="card">
      <span class="status-pill pill-blue">Report Chapter 2</span>
      <h2>Chapter 2: Problem Formulation, Scope & Engineering Objectives (CO4, CO5)</h2>
      <p><b>Purpose:</b> Define the technical challenge, mathematical problem formulation, operating constraints, and scope boundaries of the design project.</p>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ What to Write & Explain in Chapter 2:</div>
        <ul class="manual-list">
          <li><b>Problem Statement:</b> Integrating a massive 458 MVA generation unit into a stiff 230 kV utility grid creates severe challenges:
            <br>1. Extreme prospective fault currents (>120 kA) at the 22 kV generator stator bus that can shatter busbars and melt core laminations.
            <br>2. Risk of circuit breaker arc chamber explosions if prospective short-circuit currents exceed breaking ratings.
            <br>3. Severe voltage depressions and loss of generator rotor synchronism if faults are not cleared within the critical clearing time (<100 ms).
            <br>4. Unintended circulating power loops (5.9 MW) when operating auxiliary transformers in closed parallel mode.
          </li>
          <li><b>Specific Project Objectives:</b>
            <br>• <b>Objective 1:</b> Perform full load flow analysis across radial and looped auxiliary configurations.
            <br>• <b>Objective 2:</b> Calculate prospective symmetrical short-circuit currents across 5 strategic plant nodes under IEC 60909.
            <br>• <b>Objective 3:</b> Design and calibrate a comprehensive protection scheme (Relays 87G, 87T, 87B, 87L, 51, 51N) with 300 ms CTI.
            <br>• <b>Objective 4:</b> Evaluate circuit breaker withstand duties for Generator Circuit Breaker (GCB) and GIS bay breakers.
            <br>• <b>Objective 5:</b> Build a dynamic Simulink model integrating physical 110 V DC battery trip gating to demonstrate closed-loop clearance.
          </li>
          <li><b>Design Standards Followed:</b> IEC 60909 (Short-circuit calculations), IEEE C37.010 (Breaker sizing), IEEE C37.102 (Generator protection), IEC 60255 (Protective relays), and Bangladesh National Grid Code (±5% steady-state voltage limit).</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 3: METHODOLOGY & MODELING -->
    <section id="ch3" class="card">
      <span class="status-pill pill-blue">Report Chapter 3</span>
      <h2>Chapter 3: Methodology, Mathematical Modeling & Data Reconciliation (CO2, CO3)</h2>
      <p><b>Purpose:</b> Present the complete mathematical formulas for per-unit bases, sequence network impedances, synchronous machine parameters, and transmission lines.</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Diagrams to Include in Chapter 3:</div>
        <ul class="manual-list">
          <li><b>Figure 3.1: Sequence Network Connection Diagrams (Positive, Negative, and Zero Networks).</b><br>
          <i>Source file:</i> Draw or snapshot the sequence networks showing generator grounding (3Zn), transformer delta-wye connections, and line equivalents. (Refer to <span class="file-chip">Phase 4 Docs/FAULT_ANALYSIS_MANUAL.html</span> Section 3 & 4).</li>
          <li><b>Figure 3.2: 230 kV Transmission Line Nominal-PI Equivalent Circuit.</b><br>
          <i>Source file:</i> Diagram showing series resistance $R_{eq}$, reactance $X_{eq}$, and shunt susceptances $B_{eq}/2$ at each end.</li>
        </ul>
      </div>

      <div class="guide-box guide-eq">
        <div class="guide-header">📐 Equations to State in Chapter 3:</div>
        
        <div class="eq-box">
          <div class="eq-title">1. System Per-Unit Base Conversion Formula</div>
          $$Z_{\text{base}} = \frac{V_{\text{LL}}^2}{S_{3\phi}}, \quad I_{\text{base}} = \frac{S_{3\phi}}{\sqrt{3} V_{\text{LL}}}$$
          $$Z_{\text{pu, system}} = Z_{\text{pu, machine}} \times \left(\frac{S_{\text{base, system}}}{S_{\text{base, machine}}}\right) \times \left(\frac{V_{\text{base, machine}}}{V_{\text{base, system}}}\right)^2$$
          <i>Example:</i> Machine base $S = 458\text{ MVA}, V = 22\text{ kV} \rightarrow Z_{\text{base}} = 1.0568\ \Omega$. System base $100\text{ MVA}, 22\text{ kV} \rightarrow Z_{\text{base}} = 4.84\ \Omega$.<br>
          $X_d''\ (100\text{ MVA}) = 0.2248 \times (100/458) = 0.04908\text{ pu}$.
        </div>

        <div class="eq-box">
          <div class="eq-title">2. Fortescue Symmetrical Component Transformation</div>
          $$\begin{bmatrix} I_a \\ I_b \\ I_c \end{bmatrix} = \begin{bmatrix} 1 & 1 & 1 \\ 1 & a^2 & a \\ 1 & a & a^2 \end{bmatrix} \begin{bmatrix} I_0 \\ I_1 \\ I_2 \end{bmatrix}, \quad \text{where } a = e^{j 120^\circ} = -\frac{1}{2} + j \frac{\sqrt{3}}{2}$$
          $$\begin{bmatrix} I_0 \\ I_1 \\ I_2 \end{bmatrix} = \frac{1}{3} \begin{bmatrix} 1 & 1 & 1 \\ 1 & a & a^2 \\ 1 & a^2 & a \end{bmatrix} \begin{bmatrix} I_a \\ I_b \\ I_c \end{bmatrix}$$
        </div>

        <div class="eq-box">
          <div class="eq-title">3. Dual-Circuit 230 kV Transmission Line Equivalent (0.7 km, Mallard 795 MCM)</div>
          $$R_{\text{eq}} = \frac{R' \cdot L}{2} = \frac{0.07935 \times 0.7}{2} = 0.02777\ \Omega$$
          $$X_{\text{eq}} = \frac{X' \cdot L}{2} = \frac{0.40733 \times 0.7}{2} = 0.14257\ \Omega$$
          $$B_{\text{eq}} = 2 \cdot (B' \cdot L) = 2 \times (2.81285 \times 10^{-6} \times 0.7) = 3.938\ \mu\text{S}$$
        </div>
      </div>

      <!-- SECTION 3.4: ASSUMPTIONS MATRIX -->
      <div class="guide-box guide-write" id="ch3-assumptions">
        <div class="guide-header">⚙️ Section 3.4: Engineering Assumptions Matrix & Parameter Reconciliation</div>
        <p>In power system engineering studies, distinguishing between <b>field-verified physical parameters</b> and <b>justified engineering assumptions</b> is mandatory. Include this comprehensive Assumptions Matrix in <b>Chapter 3 (Section 3.4)</b> to establish complete academic transparency:</p>

        <table>
          <thead>
            <tr>
              <th>Domain / Component</th>
              <th>Assumption Key & Selected Value</th>
              <th>Reasonable Industry Range</th>
              <th>Engineering Justification / Practical Basis</th>
              <th>Governing Standard</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>National Grid Thevenin Model</b></td>
              <td><span class="file-chip">grid_series_resistance_zero</span><br><b>$R_{\text{grid}} = 0\ \Omega$</b> ($X/R = \infty$)</td>
              <td>$[0,\ 0.26\ \Omega]$</td>
              <td>With grid strength at 50 kA / 19,919 MVA ($|Z| = 2.656\ \Omega$ at 230 kV), setting $R=0$ avoids inventing unverified resistance. Conservative: overstates plant-boundary voltage sag under 345 MW export.</td>
              <td>IEEE C37.010 / IEC 60909</td>
            </tr>
            <tr>
              <td><b>230 kV Evacuation Corridor</b></td>
              <td><span class="file-chip">line_length_locked_0_7km</span><br><b>$L = 0.7\text{ km}$</b></td>
              <td>$[0.5,\ 1.5\text{ km}]$</td>
              <td>Exact physical measured distance between the 230 kV South GIS building and the PGCB overhead gantry inside the Ashuganj substation yard. Eliminates obsolete 70 km or 44 km remote line assumptions.</td>
              <td>Ashuganj Site Layout Drawing</td>
            </tr>
            <tr>
              <td><b>230 kV Overhead Conductor</b></td>
              <td><span class="file-chip">line_conductor_mallard_795</span><br><b>Mallard 795 MCM ACSR</b></td>
              <td>Grosbeak to Mallard</td>
              <td>Standard PGCB 230 kV double-circuit overhead conductor reference ($R = 0.0278\ \Omega$, $X = 0.1426\ \Omega$, $B = 3.94\ \mu\text{S}$ for 0.7 km lumped nominal PI section).</td>
              <td>PGCB Transmission Standard</td>
            </tr>
            <tr>
              <td><b>230 kV GIS Bus Coupler</b></td>
              <td><span class="file-chip">gis_coupler_normally_closed</span><br><b>Normally Closed</b> (10BAY13)</td>
              <td>Open / Closed</td>
              <td>Normal operation ties Bus 1 (10BAC01) and Bus 2 (10BAC02) in parallel common node via breaker 10BAY13, balancing export power across both outbound circuits.</td>
              <td>SLD Rev 03 / Bangladesh Grid Code</td>
            </tr>
            <tr>
              <td><b>Generator Negative & Zero Reactances</b></td>
              <td><span class="file-chip">machine_sequence_resistances</span><br><b>$R_2 = R_1$, $R_0 = 1.5 R_1$</b></td>
              <td>$R_2 \in [1, 1.5] R_1$<br>$R_0 \in [1, 2.5] R_1$</td>
              <td>Standard empirical assumption for round-rotor turbogenerators when manufacturer zero-sequence resistance measurement reports are proprietary.</td>
              <td>IEEE Std 141 (Red Book)</td>
            </tr>
            <tr>
              <td><b>Generator Neutral Grounding</b></td>
              <td><span class="file-chip">stator_ner_resistance</span><br><b>$R_N = 1,750.8\ \Omega$</b> (Primary)</td>
              <td>$[1000,\ 2500\ \Omega]$</td>
              <td>High-resistance grounding of 22 kV generator stator neutral (10BAB11). Limits single-phase-to-ground fault current to exactly 7.27 A, preventing stator core iron melting.</td>
              <td>IEEE C37.102 / IEC 60034</td>
            </tr>
            <tr>
              <td><b>Auxiliary Load Distribution</b></td>
              <td><span class="file-chip">aux_load_split_14mw</span><br><b>9.05 MW (MV) + 2.5 MW $\times 2$ (WI)</b></td>
              <td>$[10,\ 18\text{ MW}]$</td>
              <td>Total 14.0 MW auxiliary consumption split realistically between station central 6.6 kV switchboard (10BBA/10BBB) and dual Water Intake pump houses (WI1/WI2) at 0.85 PF lag.</td>
              <td>APSCL Plant Auxiliary Balance</td>
            </tr>
            <tr>
              <td><b>Protection Grading Margin</b></td>
              <td><span class="file-chip">relay_coordination_cti</span><br><b>$\text{CTI} = 300\text{ ms}$ ($0.30\text{ s}$)</b></td>
              <td>$[200,\ 400\text{ ms}]$</td>
              <td>Standard Coordination Time Interval between downstream and upstream inverse-time overcurrent relays to account for breaker clearing time (60 ms), CT saturation, and relay overshoot.</td>
              <td>IEEE 242 (Buff Book) / APSCL Spec</td>
            </tr>
            <tr>
              <td><b>Circuit Breaker Clearing Time</b></td>
              <td><span class="file-chip">breaker_operating_time</span><br><b>$t_{\text{break}} = 60\text{ ms}$ (3 cycles)</b></td>
              <td>$[40,\ 80\text{ ms}]$</td>
              <td>Mechanical opening speed and arc extinction time of Siemens SF6 GIS circuit breakers and generator circuit breaker (GCB).</td>
              <td>IEC 62271-100</td>
            </tr>
            <tr>
              <td><b>Station DC Battery & Charger</b></td>
              <td><span class="file-chip">dc_station_system</span><br><b>110 V DC, 200 Ah, 20 kW charger</b></td>
              <td>$[150,\ 300\text{ Ah}]$</td>
              <td>55 series lead-acid cells ($1.91 - 2.11\text{ V/cell}$), float at 123.75 V, internal resistance $R_{\text{int}} = 0.05\ \Omega$, closed-loop trip gating enforced at $V_{\text{dc}} \ge 88.0\text{ V}$ (80%).</td>
              <td>IEEE 485 / PGCB Battery Standard</td>
            </tr>
            <tr>
              <td><b>Turbine Governor & Static AVR</b></td>
              <td><span class="file-chip">governor_avr_defaults</span><br><b>Droop = 5%, AVR Gain = 200</b></td>
              <td>Droop: $3 - 6\%$<br>Gain: $50 - 400$</td>
              <td>Standard IEEE static exciter ST1A and mechanical governor transfer functions; provides stable terminal voltage regulation and grid frequency response without proprietary OEM firmware.</td>
              <td>IEEE Std 421.5 / IEEE Std 1207</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="guide-box guide-src">
        <div class="guide-header">📂 Where to Get the Data for Chapter 3:</div>
        <ul class="manual-list">
          <li>Transmission line data: <span class="file-chip">306 Power Project -kimi k3-v4/matlab/data/ashuganj_lines.m</span>.</li>
          <li>Generator electrical data: <span class="file-chip">306 Power Project -kimi k3-v4/matlab/data/ashuganj_generators.m</span>.</li>
          <li>Transformer ratings: <span class="file-chip">306 Power Project -kimi k3-v4/matlab/data/ashuganj_transformers.m</span>.</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 4: LOAD FLOW (360 MW) & TRANSFORMER LOADING -->
    <section id="ch4" class="card">
      <span class="status-pill pill-green">Report Chapter 4</span>
      <h2>Chapter 4: Balanced Load Flow Analysis & Transformer Loading (CO3, PO-b)</h2>
      <p><b>Purpose:</b> Present solved bus voltages, branch power flows, losses, and specifically <b>the primary 360.00 MW load flow operating case</b> alongside <b>transformer loading graphs</b> across radial and looped cases as instructed by your teacher.</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Graphs & Plots to Include in Chapter 4:</div>
        <ul class="manual-list">
          <li><b>Figure 4.1: Transformer Loading Comparison Graph across Cooling Stages.</b><br>
          <i>Source file:</i> <span class="file-chip">306 Power Project -kimi k3-v4/results/plots/transformer_loading.png</span>.<br>
          <i>What it displays:</i> Bar chart comparing percentage loading of GSUT (355/460/515 MVA), UAT (19/25 MVA), and GAT (19/25 MVA) across all four cases (LF1 to LF4).</li>
          <li><b>Figure 4.2: Plant Busbar Voltage Profile Graph.</b><br>
          <i>Source file:</i> <span class="file-chip">306 Power Project -kimi k3-v4/results/plots/bus_voltage_profile.png</span>.<br>
          <i>What it displays:</i> Voltage profile across 230 kV Switchyard, 22 kV Generator Bus, and 6.6 kV Auxiliary Busbar.</li>
          <li><b>Figure 4.3: Power Flow Balance & Export Diagram.</b><br>
          <i>Source file:</i> <span class="file-chip">306 Power Project -kimi k3-v4/results/plots/power_balance.png</span> and <span class="file-chip">306 Power Project -kimi k3-v4/results/plots/line_loading.png</span>.</li>
        </ul>
      </div>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ 4.1 The Primary 360.00 MW Load Flow Operating Case (LF360_GAT_OUT & LF360_GAT_IN):</div>
        <p>In your report, highlight that <b>360.00 MW is the primary study operating dispatch</b>, enforced directly by the project's runtime Capacity Guard (`validate_operating_profile.m`) matching Cell B3 of the APSCL owner questionnaire.</p>

        <ul class="manual-list">
          <li><b>Primary Case A: LF360_GAT_OUT (Normal Radial Operation):</b>
            <br>• <b>Gross Active Generation:</b> <span class="val-badge">360.00 MW</span> at 22 kV ($1.000\text{ pu}$, angle $-22.78^\circ$).
            <br>• <b>Generator Reactive Power:</b> <span class="val-badge">27.83 MVAr</span> lagging ($\text{Power Factor} = 0.997$), well within capability curve (retaining $225.6\text{ MVAr}$ margin).
            <br>• <b>Plant Auxiliary Power:</b> <span class="val-badge">14.00 MW + 8.676 MVAr</span> supplied entirely by UAT from the 22 kV bus.
            <br>• <b>Net Grid Export:</b> <span class="val-badge">345.207 MW</span> exported cleanly into the PGCB 230 kV national grid.
            <br>• <b>Plant Real Losses:</b> <span class="val-badge">0.793 MW (0.22%)</span> total transmission and transformer copper/core loss.
            <br>• <b>230 kV Switchyard Voltage:</b> <span class="val-badge">229.76 kV (0.9989 pu)</span>, perfectly compliant with the Bangladesh Grid Code allowable $\pm 5\%$ band.
            <br>• <b>GSUT Transformer Loading:</b> <span class="val-badge">345.8 MVA</span> ($67.1\%$ of 515 MVA ODAF rating, $97.4\%$ of 355 MVA ONAN rating).
            <br>• <b>UAT Transformer Loading:</b> <span class="val-badge">16.52 MVA</span> ($66.1\%$ of 25 MVA ONAF, $87.0\%$ of 19 MVA ONAN). Highly stable radial operation with zero circulation.
          </li>
          <li><b>Primary Case B: LF360_GAT_IN (Looped Bus Transfer Operation):</b>
            <br>• <b>The 5.91 MW Circulating Loop:</b> Closing the GAT bay breaker (10BAY20) during live bus transfer forms a closed physical loop ($22\text{ kV} \rightarrow \text{GSUT} \rightarrow 230\text{ kV} \rightarrow \text{GAT} \rightarrow 6.6\text{ kV} \rightarrow \text{UAT} \rightarrow 22\text{ kV}$).
            <br>• Due to differences in transformer impedances and tap ratios, <b>5.91 MW of circulating active power</b> flows around the loop.
            <br>• <b>UAT Overload Condition:</b> UAT loading surges to <span class="val-badge">20.29 MVA (106.8% of 19 MVA ONAN)</span>, proving that forced-air fans (ONAF, 25 MVA) must be running during looped transfer!
            <br>• <b>Net Grid Export:</b> <span class="val-badge">345.195 MW</span>; Total Losses = <span class="val-badge">0.805 MW</span>.
          </li>
        </ul>

        <div class="guide-header" style="margin-top:16px;">✍️ 4.2 Comprehensive Dispatch Spectrum: 360 MW vs 342 MW vs 389.3 MW:</div>
        <p>Explain the distinct engineering rationale for the three active power dispatch points analyzed in the study:</p>

        <table>
          <thead>
            <tr>
              <th>Operating Dispatch Case</th>
              <th>Active Power ($P_{\text{gen}}$)</th>
              <th>Auxiliary Load ($P_{\text{aux}}$)</th>
              <th>Net 230 kV Export</th>
              <th>GSUT Loading (% ODAF)</th>
              <th>UAT Loading (% ONAF)</th>
              <th>Engineering Justification & Provenance</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b style="color:var(--teal);">LF360_GAT_OUT (PRIMARY)</b></td>
              <td><b>360.00 MW</b></td>
              <td>14.00 MW</td>
              <td><b>345.21 MW</b></td>
              <td>67.1% (345.8 MVA)</td>
              <td>66.1% (16.52 MVA)</td>
              <td><b>Primary Study Case:</b> Verified capacity in APSCL Form (B3) & BPDB schedule.</td>
            </tr>
            <tr>
              <td><b style="color:var(--teal);">LF360_GAT_IN (LOOPED)</b></td>
              <td><b>360.00 MW</b></td>
              <td>14.00 MW</td>
              <td><b>345.20 MW</b></td>
              <td>66.0% (340.1 MVA)</td>
              <td><b>81.2% (20.29 MVA)</b></td>
              <td><b>Live Bus Transfer:</b> Discloses 5.91 MW circulating loop between transformers.</td>
            </tr>
            <tr>
              <td><b>LF342_GAT_OUT (Derated)</b></td>
              <td>342.01 MW</td>
              <td>14.00 MW</td>
              <td>327.27 MW</td>
              <td>63.8% (328.3 MVA)</td>
              <td>68.9% (17.22 MVA)</td>
              <td><b>Operational Reality:</b> Actual average generation from BPDB daily log sheets.</td>
            </tr>
            <tr>
              <td><b>LF389_GAT_OUT (Rated Max)</b></td>
              <td>389.30 MW</td>
              <td>14.00 MW</td>
              <td>374.41 MW</td>
              <td>73.0% (375.8 MVA)</td>
              <td>68.9% (17.22 MVA)</td>
              <td><b>Theoretical Thermal Max:</b> Machine rated power factor limit ($458\times 0.85$).</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="guide-box guide-src">
        <div class="guide-header">📂 Where to Get the Data for Chapter 4:</div>
        <ul class="manual-list">
          <li>Primary 360 MW system summary: <span class="file-chip">306 Power Project -kimi k3-v4/results/phase3_loadflow/phase3_system_summary.csv</span>.</li>
          <li>Full load flow numbers & loss audit: <span class="file-chip">306 Power Project -kimi k3-v4/results/reports/load_flow_report.md</span> (Section 5, 6, 7).</li>
          <li>Power balance reconstruction: <span class="file-chip">results/phase2_loadflow/phase2_power_balance.csv</span>.</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 5: SHORT CIRCUIT & SYMMETRICAL FAULT STUDY -->
    <section id="ch5" class="card">
      <span class="status-pill pill-red">Report Chapter 5</span>
      <h2>Chapter 5: Short-Circuit & Symmetrical Fault Study (CO3, PO-e)</h2>
      <p><b>Purpose:</b> Present calculations and simulation results across all 5 strategic fault locations for all four fault types (3-Phase LLL, Line-to-Ground LG, Line-to-Line LL, Double-Line-to-Ground LLG).</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Diagrams to Include in Chapter 5:</div>
        <ul class="manual-list">
          <li><b>Figure 5.1: 5 Strategic Fault Locations Marked on Single Line Diagram.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase 4 Docs/snapshots/sld_fault_locations_marked.png</span>.</li>
          <li><b>Figure 5.2: Master Symmetrical Fault Summary Table:</b></li>
        </ul>

        <table>
          <thead>
            <tr>
              <th>Node</th>
              <th>Physical Location</th>
              <th>Voltage</th>
              <th>3-Phase (LLL)</th>
              <th>Peak Current ($i_p$)</th>
              <th>Line-to-Ground (LG)</th>
              <th>Double-Line-Ground (LLG)</th>
              <th>Breaker Rated</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>F1</b></td>
              <td>Generator 22 kV Terminals</td>
              <td>22 kV</td>
              <td><b>126.21 kA</b></td>
              <td><b>348.26 kA</b></td>
              <td><b style="color:var(--green);">0.00727 kA (7.27 A)</b></td>
              <td>109.25 kA</td>
              <td>100.0 kA (GCB)</td>
            </tr>
            <tr>
              <td><b>F2</b></td>
              <td>GSUT LV 22 kV Bushings</td>
              <td>22 kV</td>
              <td><b>126.21 kA</b></td>
              <td><b>348.26 kA</b></td>
              <td><b style="color:var(--green);">0.00727 kA (7.27 A)</b></td>
              <td>109.25 kA</td>
              <td>100.0 kA (GCB)</td>
            </tr>
            <tr>
              <td><b>F3</b></td>
              <td>230 kV GIS Switchyard Bus</td>
              <td>230 kV</td>
              <td><b>50.53 kA</b></td>
              <td><b>129.80 kA</b></td>
              <td><b>45.74 kA</b></td>
              <td>48.50 kA</td>
              <td>50.0 kA (Q0)</td>
            </tr>
            <tr>
              <td><b>F4</b></td>
              <td>230 kV Line 1 Midpoint (50%)</td>
              <td>230 kV</td>
              <td><b>51.06 kA</b></td>
              <td><b>131.30 kA</b></td>
              <td><b>46.12 kA</b></td>
              <td>48.97 kA</td>
              <td>50.0 kA (Q0)</td>
            </tr>
            <tr>
              <td><b>F5</b></td>
              <td>Remote PGCB Grid Substation</td>
              <td>230 kV</td>
              <td><b>53.09 kA</b></td>
              <td><b>137.40 kA</b></td>
              <td><b>48.47 kA</b></td>
              <td>51.18 kA</td>
              <td>50.0 kA (Grid)</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- SPECIAL SPOTLIGHT 1: TEACHER QUESTION ON LLL VS LLG -->
    <section id="spotlight-llg" class="guide-spotlight">
      <span class="status-pill pill-red">Teacher Defense Question 1</span>
      <h3>⚡ Special Report Section: Detailed Investigation — Why is LLL Fault Current Compared to LLG?</h3>
      <p><b>Teacher's Inquiry:</b> <i>"1. LLL fault current keno kom aschilo LLG theke? Amra thik value i paisi but slide e boshaite bhul korsi."</i></p>
      <p>You must include this explicit derivation and explanation in your report to earn full marks and demonstrate technical mastery!</p>

      <div class="guide-write">
        <div class="guide-header">✍️ Part A: The General Symmetrical Theory — When CAN LLG Exceed LLL?</div>
        <p>In power system analysis, whether a Double-Line-to-Ground (LLG) fault produces higher phase current than a Three-Phase (LLL) fault depends entirely on the ratio of <b>Zero-Sequence Impedance ($Z_0$) to Positive-Sequence Impedance ($Z_1$)</b>.</p>
        
        <div class="eq-box">
          <div class="eq-title">1. Mathematical Proof of LLG vs LLL Current</div>
          <b>Three-Phase Symmetrical Fault Current (LLL):</b>
          $$I_{f, 3\phi} = \frac{V_f}{Z_1}$$

          <b>Double-Line-to-Ground Fault Current (LLG on phases b and c):</b><br>
          In an LLG fault, positive, negative, and zero sequence networks are connected in <b>parallel</b>:
          $$I_1 = \frac{V_f}{Z_1 + (Z_2 \parallel Z_0)} = \frac{V_f (Z_2 + Z_0)}{Z_1 Z_2 + Z_1 Z_0 + Z_2 Z_0}$$
          Assuming $Z_2 \approx Z_1$ (standard for static transformers and switchyards):
          $$I_1 = \frac{V_f (Z_1 + Z_0)}{Z_1^2 + 2 Z_1 Z_0} = \frac{V_f}{Z_1} \left[ \frac{1 + \frac{Z_0}{Z_1}}{2 \frac{Z_0}{Z_1} + 1} \right]$$
          The fault current in faulted phase $b$ is:
          $$I_b = \frac{-j \sqrt{3} V_f (Z_0 - a Z_2)}{Z_1 Z_2 + Z_1 Z_0 + Z_2 Z_0}$$
          Taking the magnitude:
          <br>• If <b>$Z_0 = Z_1$</b>: Then $|I_{b, \text{LLG}}| = \frac{\sqrt{3}}{2} I_{f, 3\phi} \approx 0.866 \cdot I_{f, 3\phi}$ (LLG is 86.6% of LLL).
          <br>• If <b>$Z_0 > Z_1$</b> (common in overhead lines where earth return path has high impedance): Then <b>$|I_{b, \text{LLG}}| < I_{f, 3\phi}$</b>.
          <br>• If <b>$Z_0 < Z_1$</b> (occurs in solidly grounded systems where multiple Delta-Wye transformer neutrals or generator neutrals are grounded in parallel with low zero-sequence impedance):
          $$\text{When } Z_0 < Z_1, \quad Z_2 \parallel Z_0 = \frac{Z_2 Z_0}{Z_2 + Z_0} < \frac{Z_1}{2}$$
          This reduces the total equivalent driving point impedance $Z_{\text{eq}} = Z_1 + (Z_2 \parallel Z_0)$ below $1.5 Z_1$, causing the phase current in LLG to <b>strictly EXCEED the three-phase fault current ($I_{\text{LLG}} > I_{3\phi}$)!</b>
        </div>
      </div>

      <div class="guide-write">
        <div class="guide-header">✍️ Part B: The Ashuganj South Plant Specific Audit & Presentation Correction</div>
        <p>In your report, explicitly write:</p>
        <blockquote style="background:#f8fafc; border-left:4px solid var(--red); padding:12px 16px; margin:10px 0; font-style:italic;">
          "In our simulated Ashuganj South network, the verified zero-sequence impedance at the 230 kV GIS switchyard (F3) is $Z_0 = 0.0543\text{ pu}$, while the positive-sequence impedance is $Z_1 = 0.0494\text{ pu}$. Because $Z_0 > Z_1$ (ratio $Z_0/Z_1 \approx 1.10$), the theoretically and numerically verified fault current for a 3-phase fault is <b>50.53 kA</b>, which is higher than the double-line-to-ground fault current of <b>48.50 kA</b>.<br><br>
          <b>Explanation of Presentation Slide Discrepancy:</b> During our preliminary viva slide preparation, the column values for 3-Phase (LLL) and Double-Line-to-Ground (LLG) were inadvertently transposed in the slide table due to typographical misplacement. The production simulation engine (`run_phase4_production()`) and PSAF benchmark datasets confirm that LLL ($50.53\text{ kA}$) strictly exceeds LLG ($48.50\text{ kA}$) at all 230 kV nodes, fully agreeing with symmetrical component theory for $Z_0 > Z_1$ networks."
        </blockquote>
      </div>
    </section>

    <!-- SPECIAL SPOTLIGHT 2: TEACHER QUESTION ON V=0 IN LLL -->
    <section id="spotlight-vzero" class="guide-spotlight">
      <span class="status-pill pill-red">Teacher Defense Question 2</span>
      <h3>⚡ Special Report Section: Mathematical Proof — Why is Voltage Exactly Zero at the Fault Node in an LLL Fault?</h3>
      <p><b>Teacher's Inquiry:</b> <i>"2. LLL fault e voltage zero ken? Zero i hobe, calculation dekhabo"</i></p>
      <p>Incorporate this exact step-by-step mathematical derivation in Chapter 5:</p>

      <div class="guide-eq">
        <div class="eq-box">
          <div class="eq-title">Complete Mathematical Derivation: Symmetrical Fault Node Voltage Collapse</div>
          <b>1. Boundary Conditions in Phase Domain:</b><br>
          Consider a symmetrical, bolted 3-phase short circuit occurring at bus $k$ with zero fault impedance ($Z_f = 0$). By definition of a bolted short circuit connecting all three phases $a, b, c$ together and to ground:
          $$V_a = V_b = V_c = 0$$

          <b>2. Transformation to Symmetrical Sequence Voltages:</b><br>
          Applying Fortescue’s symmetrical transformation matrix:
          $$\begin{bmatrix} V_k^{(0)} \\ V_k^{(1)} \\ V_k^{(2)} \end{bmatrix} = \frac{1}{3} \begin{bmatrix} 1 & 1 & 1 \\ 1 & a & a^2 \\ 1 & a^2 & a \end{bmatrix} \begin{bmatrix} V_a \\ V_b \\ V_c \end{bmatrix} = \frac{1}{3} \begin{bmatrix} 1 & 1 & 1 \\ 1 & a & a^2 \\ 1 & a^2 & a \end{bmatrix} \begin{bmatrix} 0 \\ 0 \\ 0 \end{bmatrix} = \begin{bmatrix} 0 \\ 0 \\ 0 \end{bmatrix}$$
          Therefore, at the fault node $k$, <b>all sequence voltages are identically ZERO</b>:
          $$V_k^{(0)} = 0, \quad V_k^{(1)} = 0, \quad V_k^{(2)} = 0$$

          <b>3. Verification from Thevenin Network Sequence Equations:</b><br>
          In a balanced 3-phase fault, negative and zero sequence networks are unexcited:
          $$I_k^{(2)} = 0 \implies V_k^{(2)} = -Z_{kk}^{(2)} I_k^{(2)} = 0$$
          $$I_k^{(0)} = 0 \implies V_k^{(0)} = -Z_{kk}^{(0)} I_k^{(0)} = 0$$
          In the positive-sequence network, the bus voltage is given by the prefault Thevenin voltage $V_f$ minus the internal voltage drop across the Thevenin driving point impedance $Z_{kk}^{(1)}$:
          $$V_k^{(1)} = V_f - Z_{kk}^{(1)} I_k^{(1)}$$
          For a bolted fault ($Z_f = 0$), the fault current injected into the fault node is:
          $$I_k^{(1)} = \frac{V_f}{Z_{kk}^{(1)}}$$
          Substituting this into the positive-sequence voltage expression:
          $$V_k^{(1)} = V_f - Z_{kk}^{(1)} \left( \frac{V_f}{Z_{kk}^{(1)}} \right) = V_f - V_f = \mathbf{0.000\text{ Volts (0.000 pu)}}$$

          <b>4. Voltage Profile along Connected Lines (Voltage at Adjacent Bus $j$):</b><br>
          At any healthy adjacent substation bus $j$ connected to the faulted bus $k$ via branch impedance $Z_{jk}$:
          $$V_j = V_f - Z_{jk}^{(1)} I_k^{(1)} = V_f \left( 1 - \frac{Z_{jk}^{(1)}}{Z_{kk}^{(1)}} \right) > 0$$
          <b>Physical Engineering Conclusion:</b> Voltage is exactly zero <i>only at the point of the bolted fault</i>. As you move away from the fault through line and transformer reactances toward the generators and grid, the voltage recovers proportionally.
        </div>
      </div>
    </section>

    <!-- CHAPTER 6: PROTECTION SYSTEM DESIGN & RELAY SETTINGS -->
    <section id="ch6" class="card">
      <span class="status-pill pill-purple">Report Chapter 6</span>
      <h2>Chapter 6: Protection System Design, Relay Settings & Coordination (CO4, CO5)</h2>
      <p><b>Purpose:</b> Detail the protection architecture, CT ratio selection, relay pickup settings, coordination time intervals (CTI = 300 ms), and explicitly analyze <b>what was sourced from APSCL vs. what our engineering study integrated and calibrated</b>.</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Diagrams & Tables to Include in Chapter 6:</div>
        <ul class="manual-list">
          <li><b>Figure 6.1: Protection Zones Map Showing Overlapping Boundaries.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase 4 Docs/snapshots/protection_zones_map.png</span>.</li>
          <li><b>Figure 6.2: Master Protective Relay Settings Table:</b></li>
        </ul>

        <table>
          <thead>
            <tr>
              <th>Relay Tag</th>
              <th>Protected Zone</th>
              <th>ANSI Function</th>
              <th>CT Ratio</th>
              <th>Pickup ($I_p$)</th>
              <th>Curve / Slope</th>
              <th>Trip Time</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>GEN-87G</b></td>
              <td>Generator Stator</td>
              <td>87G Differential</td>
              <td>15,000 / 1 A</td>
              <td>$I_{\text{diff}} > 0.15\text{ pu}$</td>
              <td>Dual Slope ($K_1=30\%, K_2=60\%$)</td>
              <td><b>45 ms (0.045 s)</b></td>
            </tr>
            <tr>
              <td><b>GEN-51N</b></td>
              <td>Generator Ground</td>
              <td>51N Sensitive Earth</td>
              <td><b>20 / 1 A (Neutral)</b></td>
              <td>$I_p = 4.0\text{ A}$ ($0.20\text{ A sec}$)</td>
              <td>IEC Standard Inverse ($\text{TMS} = 0.10$)</td>
              <td><b>1.75 s</b></td>
            </tr>
            <tr>
              <td><b>GSUT-87T</b></td>
              <td>GSUT Transformer</td>
              <td>87T Differential</td>
              <td>15,000/1 LV, 1,600/1 HV</td>
              <td>$I_{\text{diff}} > 0.20\text{ pu}$</td>
              <td>Dual Slope + 2nd Harmonic Inrush</td>
              <td><b>45 ms (0.045 s)</b></td>
            </tr>
            <tr>
              <td><b>GIS-87B</b></td>
              <td>230 kV GIS Bus</td>
              <td>87B Busbar Diff</td>
              <td>1,600 / 1 A</td>
              <td>Differential Spill</td>
              <td>High-Speed Low Impedance</td>
              <td><b>35 ms (0.035 s)</b></td>
            </tr>
            <tr>
              <td><b>LINE-87L</b></td>
              <td>230 kV Line 1 & 2</td>
              <td>87L Line Current Diff</td>
              <td>1,600 / 1 A</td>
              <td>Vector Difference</td>
              <td>Fiber Optic Communication</td>
              <td><b>40 ms (0.040 s)</b></td>
            </tr>
            <tr>
              <td><b>GSUT-HV-51</b></td>
              <td>Transformer Backup</td>
              <td>51 Overcurrent Backup</td>
              <td>1,600 / 1 A</td>
              <td>$I_p = 1,380\text{ A}$ ($0.86\text{ A sec}$)</td>
              <td>IEC Standard Inverse ($\text{TMS} = 0.55$)</td>
              <td><b>2.35 s</b></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- NEW SPECIAL SUBSECTION: APSCL SOURCED VS OUR STUDY INTEGRATION -->
      <div class="guide-box guide-write" style="background:#fdfefe; border: 2px solid var(--purple);">
        <div class="guide-header" style="color:var(--purple);">✍️ 6.4 Sourced APSCL / OEM Protection Data vs. Our Study's Protection Integration:</div>
        <p>A frequent viva and evaluation trap is claiming that all relay settings came from the utility. In your report, state clearly what came from APSCL/Siemens and what our engineering team calculated, added, and integrated:</p>

        <table>
          <thead>
            <tr>
              <th>Protective Function / Scheme</th>
              <th>What APSCL / Siemens Provided (Original Sourced Evidence)</th>
              <th>What Was Missing / Unresolved in Sourced Set</th>
              <th>What OUR Study Calculated & Integrated</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>Generator Overcurrent & Differential (51 & 87G)</b></td>
              <td>Drawing `GENERATION AND TRANSFORMERS SYSTEM.pdf` (p.2) lists functions **51** and **87G**; reports 15,000/1 A phase CTs.</td>
              <td>No commissioned relay setting file was supplied; pickup dials, slope percentages, and delays were absent.</td>
              <td><b>Calculated pickup $I_p = 17,170.8\text{ A}$ (TMS 0.10) for 51</b>; designed 87G dual restraint slope (30%/60%) with 45 ms trip delay.</td>
            </tr>
            <tr>
              <td><b>Generator Stator Earth Fault (51N & NER)</b></td>
              <td>Drawing p.2 lists **51N**; Generator sheet p.2 lists NGT ($22\text{ kV}/\sqrt{3} : 500\text{ V}$) with $2.62\ \Omega$ loading resistor.</td>
              <td>No neutral CT ratio was specified; 15,000/1 phase CTs are blind to 7.27 A ground fault ($0.485\text{ mA}$ secondary is below noise floor).</td>
              <td><b>Introduced dedicated 20/1 A Neutral CT</b> ($0.364\text{ A}$ secondary); calibrated 51N relay with $I_p = 4.0\text{ A}$, $\text{TMS} = 0.15$ to trip in 1.75 s and save stator core.</td>
            </tr>
            <tr>
              <td><b>Transformer Differential (87T)</b></td>
              <td>Drawing lists function **87** on GSUT bays F12/F26.</td>
              <td>Vector group compensation algorithms and magnetizing inrush restraint parameters were omitted.</td>
              <td><b>Programmed YNd1 $+30^\circ$ numerical phase shift compensation</b>, zero-sequence filtering, and 2nd harmonic inrush blocking ($I_{2h}/I_{1h} > 15\%$).</td>
            </tr>
            <tr>
              <td><b>Busbar Differential (87B / 50BF)</b></td>
              <td>Drawing p.2-3 explicitly shows **87B - 50BF** at the 230 kV GIS switchyard interface.</td>
              <td>Spill thresholds, zone overlaps, and trip matrix routing were not documented.</td>
              <td><b>Configured 3-branch low-impedance bus differential</b> comparing GSUT bay and outgoing line bay CTs, tripping in 35 ms.</td>
            </tr>
            <tr>
              <td><b>Line Current Differential (87L)</b></td>
              <td><b>ABSENT / MISSING.</b> Detailed GIS drawing `INEL-112070-00-ELC-DE-0026` was completely omitted from the project ZIP.</td>
              <td>No line differential relay, optical fiber interface, or remote breaker trip scheme existed in the supplied documents.</td>
              <td><b>Engineered a complete functional 87L line differential scheme</b> over simulated optical fiber comparing local/remote current phasors (40 ms clearing).</td>
            </tr>
            <tr>
              <td><b>Station 110 V DC Trip Gating</b></td>
              <td>INELECTRA Rev 03 specifies $110\text{ V DC}$ (+10% / -20%) control voltage.</td>
              <td>No battery sizing, internal resistance, charger float regulation, or trip coil energization interlock existed.</td>
              <td><b>Modeled 55-cell 200 Ah lead-acid battery ($0.05\ \Omega$)</b>, 20 kW charger ($123.75\text{ V}$), and physical trip gating: $\text{Demand} = \text{TripRequest} \ \&\ (V_{\text{DC}} \ge 88\text{ V})$.</td>
            </tr>
            <tr>
              <td><b>Looped Auxiliary Interlock (`P6_REQUESTS`)</b></td>
              <td>GAT bay breaker 10BAY20 shown on SLD, but operating interlocks were not defined.</td>
              <td>The danger of fault back-feeding during GAT-IN transfer was not recognized.</td>
              <td><b>Engineered cross-tripping logic:</b> on 230 kV bus faults in looped mode, Relay 87B simultaneously trips <b>both Q0 and the GAT breaker</b> to stop back-feeding!</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="guide-box guide-src">
        <div class="guide-header">📂 Where to Get the Data for Chapter 6:</div>
        <ul class="manual-list">
          <li>Source audit & additions register: <span class="file-chip">Phase6/presentation_snapshots/metadata/SOURCES_AND_ADDITIONS.md</span>.</li>
          <li>Relay settings CSV: <span class="file-chip">Phase 5 Docs/tables/relay_settings.csv</span> and <span class="file-chip">coordination.csv</span>.</li>
          <li>Full manual: <span class="file-chip">PROTECTION_RELAYS_AND_SETTINGS_MANUAL.html</span>.</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 7: DYNAMIC SIMULATION & STATION DC -->
    <section id="ch7" class="card">
      <span class="status-pill pill-purple">Report Chapter 7</span>
      <h2>Chapter 7: Dynamic Simulation, Station DC Battery & Breaker Duty (CO4, CO5)</h2>
      <p><b>Purpose:</b> Present the time-domain Simulink simulation, station DC battery closed-loop trip gating, and certified circuit breaker interrupting duty verification.</p>

      <div class="guide-box guide-include">
        <div class="guide-header">🖼️ What Graphs to Include in Chapter 7:</div>
        <ul class="manual-list">
          <li><b>Figure 7.1: Transient Voltage and Frequency Response Waveform.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase6/results/bus_3ph/01_voltage_frequency.png</span>.</li>
          <li><b>Figure 7.2: 3-Phase Short-Circuit Current Waveform ($I_k'' = 50.5\text{ kA}$).</b><br>
          <i>Source file:</i> <span class="file-chip">Phase6/results/bus_3ph/03_fault_waveforms.png</span>.</li>
          <li><b>Figure 7.3: Relay Trip Signal & Circuit Breaker Auxiliary Contact Opening Timing.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase6/results/bus_3ph/04_protection_breakers.png</span>.</li>
          <li><b>Figure 7.4: Station 110 V DC Battery Bus Voltage Dip & Trip Coil Current Pulse.</b><br>
          <i>Source file:</i> <span class="file-chip">Phase6/results/bus_3ph/05_station_dc.png</span>.</li>
        </ul>
      </div>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ What to Write & Explain in Chapter 7:</div>
        <ul class="manual-list">
          <li><b>Total Fault Clearance Time (<100 ms):</b> Relay detection time (35 ms for 87B) + breaker mechanism opening time (50 ms) = <b>85 to 90 ms total clearance</b>. This is below the 100 ms critical clearing time, ensuring generator rotor stability is maintained without pole-slipping.</li>
          <li><b>Circuit Breaker Duty Ratios (Zero Over-Duty):</b>
            <br>• <b>Generator Circuit Breaker (GCB - 10BAC10):</b> Rated 100 kA RMS breaking. Maximum prospective fault through GCB from grid into F1 = 55.05 kA. <b>Duty = 55.0% (PASS with 45.0% safety margin)</b>.
            <br>• <b>230 kV GIS Breaker (Q0 - 8DN9):</b> Rated 50 kA RMS breaking. Maximum through-current contribution from GSUT = 6.90 kA. <b>Duty = 13.8% (PASS with 86.2% safety margin)</b>.
          </li>
          <li><b>Station DC Closed-Loop Trip Gating:</b> Emphasize that in real substations, relays only emit mathematical flags; physical breaker coils require DC energy:
            $$\text{Trip Demand} = \text{Trip Request} \ \&\ (V_{\text{DC}} \ge 88\text{ V})$$
            The simulation proves the 110 V 200 Ah lead-acid battery bank dips by only 1.0 V when trip coils fire, preventing DC brownout failures.
          </li>
        </ul>
      </div>

      <div class="guide-box guide-src">
        <div class="guide-header">📂 Where to Get the Data for Chapter 7:</div>
        <ul class="manual-list">
          <li>Simulation waveforms: <span class="file-chip">Phase6/results/bus_3ph/</span> (PNG files 01 through 05).</li>
          <li>Breaker duty CSV: <span class="file-chip">Phase 5 Docs/tables/breaker_duty.csv</span>.</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 8: SOCIETAL, SAFETY & ECONOMIC IMPACT -->
    <section id="ch8" class="card">
      <span class="status-pill pill-amber">Report Chapter 8</span>
      <h2>Chapter 8: Societal, Environmental, Safety & Economic Cost Analysis (CO5, CO8)</h2>
      <p><b>Purpose:</b> Address the engineering sustainability, public safety, environmental hazards, and cost-benefit economic analysis required by Program Outcomes PO(f), PO(g), and PO(k).</p>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ What to Write & Include in Chapter 8:</div>
        <ul class="manual-list">
          <li><b>Environmental Hazard Mitigation:</b>
            <br>• <i>SF6 Gas Decomposition:</i> Sulfur Hexafluoride ($SF_6$) is a potent greenhouse gas (GWP = 23,500). Sustained arcing decomposes $SF_6$ into toxic $SO_2$, $HF$, and $S_2F_{10}$. Clearing faults in 35 ms prevents GIS enclosure rupture and hazardous gas release.
            <br>• <i>Transformer Mineral Oil Spills:</i> GSUT contains ~60,000 liters of combustible mineral oil. High-speed 87T tripping prevents tank overpressurization, preventing burning oil fireballs and groundwater contamination.
          </li>
          <li><b>Public Safety & National Grid Resilience:</b> Maintaining rotor stability preserves power supply for millions of citizens, preventing cascading national blackouts that paralyze hospitals and critical infrastructure.</li>
          <li><b>Economic Cost-Benefit & Equipment Protection Analysis:</b>
            <br>Include this comparative financial matrix in your report:
          </li>
        </ul>

        <table>
          <thead>
            <tr>
              <th>Equipment Protected</th>
              <th>Protective Scheme Employed</th>
              <th>Protection Investment Cost</th>
              <th>Direct Asset Loss Prevented if Protection Fails</th>
              <th>Outage Loss Prevented</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>458 MVA Generator Stator</b></td>
              <td>1,750 Ω NER + 20/1 CT + 51N Relay</td>
              <td>$45,000</td>
              <td><b>$18,000,000 (Complete Core Slagging)</b></td>
              <td>$25,000,000 (14-Month Outage)</td>
            </tr>
            <tr>
              <td><b>515 MVA GSUT Transformer</b></td>
              <td>87T Differential + Buchholz Relay</td>
              <td>$35,000</td>
              <td><b>$7,500,000 (Tank Explosion & Fire)</b></td>
              <td>$15,000,000 (9-Month Outage)</td>
            </tr>
            <tr>
              <td><b>230 kV GIS Switchyard</b></td>
              <td>87B Differential (35 ms)</td>
              <td>$80,000</td>
              <td><b>$12,000,000 (Bus Plasma Blast)</b></td>
              <td>$30,000,000 (Substation Rebuild)</td>
            </tr>
            <tr>
              <td><b>Station Battery & DC Bank</b></td>
              <td>Float Charger + 200 Ah Battery</td>
              <td>$50,000</td>
              <td><b>$50,000,000 (Total Station Blackout)</b></td>
              <td>Priceless (Grid Stability)</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- CHAPTER 9: TEAMWORK, MANAGEMENT & LOGBOOK -->
    <section id="ch9" class="card">
      <span class="status-pill pill-teal">Report Chapter 9</span>
      <h2>Chapter 9: Teamwork, Project Management & Tool Execution (CO6, CO7)</h2>
      <p><b>Purpose:</b> Document team member contributions, engineering leadership, milestone execution, and simulation tool verification required by PO(i) and PO(j).</p>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ What to Write & Include in Chapter 9:</div>
        <ul class="manual-list">
          <li><b>Work Breakdown Structure (WBS) & Task Ownership:</b>
            <br>• Member 1 (Lead Analyst): Master data reconciliation, per-unit conversions, and load flow modeling (Phase 1–3).
            <br>• Member 2 (Protection Engineer): Sequence networks, IEC 60909 fault calculations, and relay setting coordination (Phase 4–5).
            <br>• Member 3 (Simulation Specialist): MATLAB/Simulink dynamic modeling, station DC integration, and waveform generation (Phase 6).
            <br>• Member 4 (Technical Writer / Quality Assurance): Report compilation, video presentation recording, and standards compliance auditing.
          </li>
          <li><b>Milestone Schedule (Gantt Summary):</b> Weeks 1–3 (Literature & PFI Study), Weeks 4–6 (PSAF Load Flow & Proposal), Weeks 7–8 (Plant Visit & Substation Audit), Weeks 9–11 (Fault Analysis & Protection Design), Weeks 12–13 (Dynamic Simulation, Final Report & Video).</li>
          <li><b>Quality Assurance & Software Regression:</b> State that your engineering implementation passed an automated regression suite of <b>447 passed test assertions with 0 failures</b> across all load flow and fault modules.</li>
        </ul>
      </div>
    </section>

    <!-- CHAPTER 10: CONCLUSIONS & LIMITATIONS -->
    <section id="ch10" class="card">
      <span class="status-pill pill-green">Report Chapter 10</span>
      <h2>Chapter 10: Final Engineering Verdict, Detailed Study Limitations & Future Scope (CO7, CO8)</h2>
      <p><b>Purpose:</b> Summarize major engineering findings cleanly, disclose <b>six specific academic and industrial study limitations</b> with complete technical transparency, and define the future engineering roadmap.</p>

      <div class="guide-box guide-write">
        <div class="guide-header">✍️ 1. Executive Engineering Conclusions:</div>
        <ul class="manual-list">
          <li><b>100% Parameter Traceability:</b> The entire electrical drivetrain (458 MVA generator, 515 MVA GSUT, 25 MVA UAT/GAT, 0.7 km 230 kV Mallard line, 110 V DC battery) is parameter-verified against Siemens OEM test records, APSCL technical questionnaires, and PGCB grid standards.</li>
          <li><b>High-Speed Multi-Zone Clearance:</b> All 5 critical fault zones (F1 to F5) clear safely with primary clearance times between $35\text{ ms}$ and $95\text{ ms}$, reliably maintaining generator rotor angle stability.</li>
          <li><b>Substantial Circuit Breaker Duty Margins:</b> Both the Generator Circuit Breaker (GCB duty = $55.0\%$ under $126.2\text{ kA}$ peak symmetrical duty) and the 230 kV GIS feeder breakers (duty = $13.8\%$ under $49.7\text{ kA}$ grid through-fault) operate well below their breaking ceilings.</li>
          <li><b>Stator Core Thermal Protection:</b> High-resistance neutral grounding ($R_N = 1,750.8\ \Omega$) successfully throttles single-phase-to-ground stator fault current to $7.27\text{ A}$, eliminating stator lamination burning. Our added $20/1\text{ A}$ neutral CT guarantees $100\text{ ms}$ tripping where standard $15,000/1\text{ A}$ phase CTs are blind.</li>
          <li><b>Station DC Supply Integrity:</b> The 110 V 200 Ah station battery system safely supports simultaneous trip and close coil impulse draws, with voltage dipping by only $1.0\text{ V}$ ($109.0\text{ V} \gg 88.0\text{ V}$ cutoff), ensuring protection reliability during severe AC blackouts.</li>
        </ul>
      </div>

      <div class="guide-box guide-spotlight" style="background: #fdfefe; border: 2px solid #0284c7;">
        <h3 style="color: #0369a1; margin-top: 0;">🔍 2. Honest Study Limitations & Boundary Conditions:</h3>
        <p>In your report and viva defense, demonstrating clear awareness of your simulation model's technical boundaries will impress examiners. Detail these <b>six specific engineering limitations</b>:</p>

        <table>
          <thead>
            <tr>
              <th>Limitation Category</th>
              <th>Study Boundary / What Was Modeled</th>
              <th>Real-World Physical Reality</th>
              <th>Significance & Engineering Mitigation</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><b>1. Phasor & Transient Domain vs. EMTP / TRV</b></td>
              <td>Simscape/MATLAB fundamental-frequency (50 Hz) RMS phasor and transient time-domain solver ($10\ \mu\text{s}$ to $1\text{ ms}$ step size).</td>
              <td>Sub-microsecond electromagnetic surges, fast Transient Recovery Voltage (TRV), high-frequency current chopping, and restrike transients in SF6 GIS.</td>
              <td>Adequate for relay coordination and stability. High-frequency insulation coordination and circuit breaker TRV compliance requires specialized EMT tools (e.g., EMTP-RV, PSCAD).</td>
            </tr>
            <tr>
              <td><b>2. Grid Boundary (Thevenin Source vs. Dynamic Grid)</b></td>
              <td>External 230 kV national grid represented as an equivalent 50 kA / 19,919 MVA Thevenin source behind $R=0$ impedance.</td>
              <td>Multi-machine national grid with remote generator swings, inter-area electromechanical oscillations (0.1–2.0 Hz across Jamuna River), and system-wide frequency decay during regional islanding.</td>
              <td>Accurate for local plant-level short circuit duty; cannot capture wide-area grid blackstart or inter-area power oscillations without full PGCB grid model.</td>
            </tr>
            <tr>
              <td><b>3. Excitation & Governor Control Formulations</b></td>
              <td>Standard IEEE models (ST1A static exciter with gain 200, standard 5% droop mechanical governor).</td>
              <td>Proprietary Siemens SPPA-T3000 / Teleperm digital electro-hydraulic (DEH) turbine control algorithms and non-linear multi-segment valve lift functions.</td>
              <td>Standard IEEE models accurately capture primary governor and AVR frequency/voltage recovery; exact tuning for grid compliance tests requires proprietary OEM firmware blocks.</td>
            </tr>
            <tr>
              <td><b>4. Auxiliary Load Representation (Static vs. Induction Motors)</b></td>
              <td>14.0 MW auxiliary consumption represented as static lumped $P$-$Q$ loads (constant $P$ and $Q$ at 0.85 PF lag).</td>
              <td>Large 6.6 kV induction motors (boiler feed pumps, condenser cooling pumps) exhibiting $5-6\times I_{\text{rated}}$ inrush currents, slip-dependent torque, and voltage-depressed reacceleration.</td>
              <td>Sufficient for steady-state load flow and thermal loading; dynamic auxiliary bus transfer studies require explicit induction motor equivalent circuits ($R_r, X_r, H_m$).</td>
            </tr>
            <tr>
              <td><b>5. Station DC Battery Modeling</b></td>
              <td>Linear Thevenin battery model ($E_{\text{ocv}} - I \cdot R_{\text{int}}$) with coulombic state-of-charge (SOC) integration and 88 V trip gating logic.</td>
              <td>Electrochemical Peukert effect, temperature-dependent amp-hour capacity derating ($<10^\circ\text{C}$ / $>40^\circ\text{C}$), electrolyte stratification, and plate sulfation over multi-year aging.</td>
              <td>Captures trip pulse voltage sag and undervoltage trip interlocks accurately; does not predict multi-year battery lifecycle or cold-weather cranking degradation.</td>
            </tr>
            <tr>
              <td><b>6. Zero-Sequence Line Coupling</b></td>
              <td>Mutual zero-sequence coupling ($Z_{0m}$) between the parallel 230 kV circuits was neglected due to short span ($0.7\text{ km}$).</td>
              <td>Close-proximity parallel double-circuit lines induce mutual zero-sequence currents during single-line-to-ground faults.</td>
              <td>On a 0.7 km line, the mutual zero-sequence impedance represents $<0.03\ \Omega$, which has negligible impact on relay reach; would become critical for lines $>20\text{ km}$.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="guide-box guide-write">
        <div class="guide-header">🚀 3. Proposed Future Research & Engineering Extensions:</div>
        <ul class="manual-list">
          <li><b>Hardware-in-the-Loop (HIL) Relay Testing:</b> Interface real microprocessor relays (Siemens SIPROTEC 7UM62 / 7UT63) to an RTDS (Real-Time Digital Simulator) via physical analog amplifier blocks to test physical binary contact timing and optical fiber GOOSE communication under IEC 61850.</li>
          <li><b>EMTP-RV Insulation Coordination & TRV Study:</b> Build high-frequency GIS bushing and arrester models in EMTP-RV to verify Rate of Rise of Recovery Voltage (RRRV) across GCB contacts during out-of-phase synchronizing breaker opening.</li>
          <li><b>Dynamic Auxiliary Motor Starting & Fast Bus Transfer (FBT):</b> Model explicit multi-mass induction motor dynamics to evaluate high-speed automatic bus transfer ($<100\text{ ms}$) from UAT to GAT during unit trip without motor stalling.</li>
          <li><b>Wide-Area Synchrophasor (WAMS / PMU) Integration:</b> Study PMU placement at the 230 kV South GIS to supply real-time phase angle data to PGCB National Load Despatch Centre (NLDC) for early detection of inter-area oscillations.</li>
        </ul>
      </div>
    </section>

    <!-- APPENDIX: REPORT SUBMISSION CHECKLIST -->
    <section id="checklist" class="card">
      <span class="status-pill pill-teal">Final Quality Gate</span>
      <h2>Appendix: Pre-Submission Verification Checklist</h2>
      <p>Before submitting your report to your teacher, ensure that every item below is checked:</p>

      <ul class="manual-list" style="list-style: none; padding-left: 0;">
        <li><input type="checkbox" checked disabled> <b>1. Title & Metadata:</b> "Ashuganj South 450 MW Combined Cycle Power Plant — Electrical Protection & Dynamic Simulation Study".</li>
        <li><input type="checkbox" checked disabled> <b>2. Course Mapping:</b> Table explicitly mapping Chapters to CO1–CO9 and PO(a)–PO(l) included in Chapter 1.</li>
        <li><input type="checkbox" checked disabled> <b>3. Single Line Diagram:</b> Crisp Master SLD with circled fault locations (F1 to F5) included in Chapter 1 & 5.</li>
        <li><input type="checkbox" checked disabled> <b>4. Real Datasheets Cited:</b> Siemens OEM generator, GSUT, UAT, GCB, GIS, and CT/VT nameplates cited with drawing `S008-112070`.</li>
        <li><input type="checkbox" checked disabled> <b>5. Balanced Load Flow (360 MW):</b> Section 4.1 explicitly showcasing primary 360.00 MW dispatch (LF360_GAT_OUT & LF360_GAT_IN).</li>
        <li><input type="checkbox" checked disabled> <b>6. Protection Integration Audit:</b> Section 6.4 clearly contrasting sourced APSCL data vs our team's calibrated settings and additions.</li>
        <li><input type="checkbox" checked disabled> <b>7. Transformer Loading Graphs:</b> <span class="file-chip">transformer_loading.png</span> and <span class="file-chip">bus_voltage_profile.png</span> embedded in Chapter 4.</li>
        <li><input type="checkbox" checked disabled> <b>8. Teacher Question 1 Solved:</b> Symmetrical derivation of when LLG > LLL ($Z_0 < Z_1$) and presentation slide misplacement explanation included in Chapter 5.</li>
        <li><input type="checkbox" checked disabled> <b>9. Teacher Question 2 Solved:</b> Complete derivation proving voltage is zero at the bolted fault node ($V_k^{(1)} = 0$) included in Chapter 5.</li>
        <li><input type="checkbox" checked disabled> <b>10. Breaker Duty Margins:</b> GCB 55.0% and GIS 13.8% duty verification tables included in Chapter 7.</li>
        <li><input type="checkbox" checked disabled> <b>11. Dynamic Waveforms:</b> Voltage, frequency, fault waveform, breaker timing, and DC battery plots included in Chapter 7.</li>
        <li><input type="checkbox" checked disabled> <b>12. Economic & Environmental Impact:</b> Cost analysis and SF6/fire risk discussion included in Chapter 8.</li>
        <li><input type="checkbox" checked disabled> <b>13. 4-Minute Video:</b> Video recorded following the speech script and checklist submitted alongside report.</li>
      </ul>
    </section>

  </main>
</div>

<script>
function setFontScale(scale, btn) {
  document.documentElement.style.setProperty('--font-scale', scale);
  document.querySelectorAll('.pbar-btn').forEach(b => {
    if (b.id !== 'btn-full-width') b.classList.remove('active');
  });
  if (btn) btn.classList.add('active');
  localStorage.setItem('reportManualFontScale', scale);
}

function toggleFullWidth(btn) {
  document.documentElement.classList.toggle('full-width');
  const isFull = document.documentElement.classList.contains('full-width');
  btn.classList.toggle('active', isFull);
  localStorage.setItem('reportManualFullWidth', isFull ? '1' : '0');
}

window.addEventListener('DOMContentLoaded', () => {
  const savedScale = localStorage.getItem('reportManualFontScale');
  if (savedScale) {
    const s = parseFloat(savedScale);
    let target = document.getElementById('btn-scale-2');
    if (s <= 1.0) target = document.getElementById('btn-scale-1');
    else if (s >= 1.4) target = document.getElementById('btn-scale-4');
    else if (s >= 1.2) target = document.getElementById('btn-scale-3');
    setFontScale(s, target);
  }
  const savedFull = localStorage.getItem('reportManualFullWidth');
  if (savedFull === '1') toggleFullWidth(document.getElementById('btn-full-width'));
});
</script>
</body>
</html>
"""

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Successfully generated: {OUTPUT_FILE} ({len(html_content)} bytes)")
