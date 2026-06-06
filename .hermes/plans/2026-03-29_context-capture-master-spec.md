# 🧠 Context Capture & RAM Pressure Monitor — Master Project Spec

**Version:** 0.3 (Post-Refinement)  
**Date:** March 29, 2026  
**Status:** Architecture Defined → Implementation Planning  
**Related:** Omni-Loop v3.0, Omniedge, SpaceVibe, Agent Swarm Architecture

---

## 🎯 Executive Summary (The Whole Vision)

A **local-first, privacy-preserving context capture system** that:

1. **Monitors RAM pressure** in real-time (traffic light UI)
2. **Auto-captures process state** when memory is critical (Chrome, CLI, IDE, editors)
3. **Associates resources to projects** via LLM + temporal rules
4. **Preserves AI conversation transcripts** (prompts + responses, not just URLs)
5. **Ingests into RAG** with quad-encoding (word/sentence/paragraph/boundary)
6. **Presents via temporal mindmap** (Hyperland/Niri-inspired infinite zoom)
7. **Learns from user feedback** ("this wasn't part of my project")

**Core Philosophy:** "We control the telemetry" — not Microsoft Copilot working ON us, but working FOR us.

---

## 🔍 Key Insights from Research

### 1. **What Makes This Novel**

| Existing Solution | What They Do | What They Miss | Our Innovation |
|-------------------|--------------|----------------|----------------|
| **Microsoft Copilot** | Tracks activity, builds context | Cloud-based, proprietary, works ON you | **Local-first, user-controlled, works FOR you** |
| **SpaceVibe** | Tab workspaces by project | Manual switching, no auto-capture | **Auto-capture + auto-associate** |
| **Session Buddy** | Crash recovery | Passive, no intelligence | **Active intelligence + project association** |
| **Omni-Loop (ByteRover/Graphiti/MemVid)** | Memory tiers for AI agents | Manual ingestion, agent-focused | **Automatic process capture + temporal association** |
| **claude-flow** | Agent orchestration | Multi-agent coordination, not context capture | **Single-user context preservation** |
| **ccswarm** | Git-based agent isolation | Development workflows only | **Full desktop context (browser, CLI, IDE, files)** |

**Our Unique Contribution:**
- **RAM pressure as trigger** — No "when does it run?" — runs when ye need it
- **CLI prompt capture** — Not just "what file" but "what was asked"
- **Temporal association engine** — "Ye didn't open notepad for no reason"
- **User feedback loop** — System learns what's work vs. break
- **Quad-encoding for RAG** — Best-in-class retrieval granularity

---

## 🏗️ Full System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAFFIC LIGHT UI (System Tray)               │
│                    [🔴] [🟡] [🔵]                               │
│                    Click: Manual capture                        │
│                    Right-click: "This wasn't my project"        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              MEMORY PRESSURE MONITOR                            │
│              - Availability (red)                               │
│              - Acceleration (yellow)                            │
│              - Duration at pressure (blue)                      │
│              Triggers at: <20% free + sustained/accel           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              PROCESS CATALOGER                                  │
│              Captures state for:                                │
│              - Chrome (tabs + AI transcripts)                   │
│              - AI CLIs (Claude, Qwen, prompts+outputs)          │
│              - IDEs (VS Code workspace, open files)             │
│              - Editors (Notepad, files + context)               │
│              - Media (Spotify, VLC — skip or minimal)           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              WORK/NON-WORK CLASSIFIER                           │
│              - Rule-based initial pass                          │
│              - LLM refinement (ambiguous cases)                 │
│              - User feedback integration                        │
│              - Outlier detection (low confidence = flag)        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              TEMPORAL ASSOCIATION ENGINE                        │
│              Groups processes into projects by:                 │
│              - Time proximity (10min window)                    │
│              - Context correlation (files, URLs)                │
│              - Clipboard correlation                            │
│              - LLM inference ("what project is this?")          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              PROJECT METADATA TAGGER (LLM)                      │
│              For each project:                                  │
│              - Generate name                                    │
│              - Infer goal/intent                                │
│              - Extract key concepts                             │
│              - Suggest next steps                               │
│              - Link to related projects                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              RAG INGESTION (Quad-Encoding)                      │
│              - Word level (snipe exact terms)                   │
│              - Sentence level (discrete facts)                  │
│              - Paragraph level (local context)                  │
│              - Boundary level (relationships)                   │
│              Stores in:                                         │
│              - ByteRover (hot, active)                          │
│              - Graphiti (warm, relationships)                   │
│              - MemVid (cold, archive)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              TEMPORAL MINDMAP UI (Hyperland-inspired)           │
│              - Infinite zoomable 2D space                       │
│              - X-axis: time, Y-axis: project clusters           │
│              - Color-coded by similarity                        │
│              - Branching (click → related)                      │
│              - Search + filter                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Process Classification Matrix

### Work vs. Non-Work Detection

| Process Type | Default | Auto-Capture | User Override Options |
|--------------|---------|--------------|----------------------|
| **Chrome (AI: claude.ai, chat.openai.com)** | Work | ✅ Full transcript | "This was a break" |
| **Chrome (Dev: GitHub, SO, docs)** | Work | ✅ URL + context | "This was a break" |
| **Chrome (YouTube)** | Ambiguous | ⚠️ URL only, flag | "Research" / "Break" |
| **Chrome (Spotify, Netflix)** | Non-work | ❌ Skip | "This was part of research" |
| **CLI (AI: claude, qwen, opencode)** | Work | ✅ Full session (prompts+outputs) | N/A |
| **CLI (Build: npm, cargo, make)** | Work | ✅ Command + output | N/A |
| **IDE (VS Code, Cursor)** | Work | ✅ Full state (workspace, files, terminals) | N/A |
| **Editor (Notepad, nvim)** | Work (assumed) | ✅ File + temporal context | "This was personal" |
| **Video Player (VLC, MPV)** | Ambiguous | ⚠️ File name only | "Research" / "Break" |
| **Music Player (Spotify)** | Non-work | ❌ Skip | "This was part of workflow" |

### Confidence Scoring

```python
def classify_work(proc_type, cmdline, context):
    if proc_type in {'ai_cli', 'ide', 'build_cli'}:
        return True, 0.9  # High confidence work

    elif proc_type == 'chrome':
        if any(site in cmdline for site in ['claude.ai', 'github.com']):
            return True, 0.8  # Likely work
        elif 'youtube.com' in cmdline:
            return None, 0.5  # Ambiguous, needs user input
        else:
            return True, 0.5  # Default to work, low confidence

    elif proc_type == 'media':
        return False, 0.8  # Likely non-work

    else:
        return None, 0.3  # Unknown, flag for review
```

---

## 🔗 Temporal Association Rules

### "Ye Didn't Open That Notepad For No Reason"

```python
# Rules for associating processes into projects

RULES = {
    'clipboard_correlation': {
        'description': 'If clipboard was copied within 2min before opening app',
        'weight': 0.8,
        'check': lambda proc, project: abs(
            proc.start_time() - project.clipboard_time
        ).seconds < 120
    },

    'file_overlap': {
        'description': 'If processes share open files or directories',
        'weight': 0.9,
        'check': lambda proc, project: any(
            f.startswith(project.workspace_root)
            for f in proc.open_files
        )
    },

    'url_similarity': {
        'description': 'If Chrome tabs share domain or path structure',
        'weight': 0.7,
        'check': lambda proc, project: (
            get_domain(proc.url) == get_domain(project.urls[0])
        )
    },

    'time_proximity': {
        'description': 'If processes started within 10min window',
        'weight': 0.6,
        'check': lambda proc, project: abs(
            proc.start_time() - project.last_activity
        ).seconds < 600
    },

    'llm_inference': {
        'description': 'LLM analyzes all context and infers project',
        'weight': 0.95,
        'check': lambda proc, project: llm.belongs_to_project(
            proc.context, project.context
        )
    }
}

# Association threshold: sum(weights) > 1.5 → same project
```

---

## 🧩 LLM Integration Points

### Where LLMs Are Used

| Stage | Purpose | Model | Frequency |
|-------|---------|-------|-----------|
| **Work Classification** | Ambiguous cases (YouTube, etc.) | Qwen-7B (local) | On-capture |
| **Project Association** | Group processes into projects | Qwen-7B (local) | On-capture |
| **Metadata Tagging** | Generate project name, goal, concepts | Qwen-7B or OpenRouter free tier | On-capture |
| **Session Summarization** | Summarize AI CLI transcripts | Qwen-7B (local) | On-capture |
| **Outlier Detection** | Learn from user feedback | Incremental training | Continuous |
| **RAG Retrieval** | Answer queries about captured context | Existing RAG system | On-demand |

### LLM Prompt Templates

```python
# Project Association Prompt
PROMPT_ASSOCIATE = """
Analyze these {n} processes and determine if they belong to the same project.

Processes:
{process_contexts}

Consider:
1. Temporal proximity (started within 10min?)
2. Shared context (files, URLs, domains)
3. Clipboard correlation
4. Semantic similarity of activities

Return JSON:
{{
  "same_project": true/false,
  "confidence": 0.0-1.0,
  "project_name_suggestion": "Name",
  "reasoning": "Why you think this"
}}
"""

# Metadata Tagging Prompt
PROMPT_METADATA = """
Analyze this captured session and generate metadata.

Session Contents:
- Chrome tabs: {tabs}
- CLI transcripts: {transcripts}
- IDE state: {ide_state}
- Files: {files}

Return JSON:
{{
  "project_name": "Descriptive name",
  "goal": "What the user was trying to accomplish",
  "key_concepts": ["concept1", "concept2"],
  "related_projects": ["project1", "project2"],
  "suggested_next_steps": ["step1", "step2"],
  "is_work": true/false,
  "work_confidence": 0.0-1.0
}}
"""
```

---

## 🗄️ RAG Integration (Quad-Encoding)

### From Omni-Loop v3.0

Each captured project gets quad-encoded:

| Level | Granularity | Use Case | Example Query |
|-------|-------------|----------|---------------|
| **Word** | Token level | Exact term lookup | "What was the variable name for retry count?" |
| **Sentence** | Discrete facts | Specific fact retrieval | "What's the return type of auth.login()?" |
| **Paragraph** | Local context | Understanding flow | "How does login handle 2FA failures?" |
| **Boundary** | Relationships | Cross-chunk connections | "What happens after login completes?" |

### Storage Tiers

| Tier | Backend | Retention | Access Pattern |
|------|---------|-----------|----------------|
| **Hot** | ByteRover (JSONL) | 0-24h active | Full-text search (ripgrep) |
| **Warm** | Graphiti (Kuzu DB) | 7-90 days | Graph traversal, relationships |
| **Cold** | MemVid (.mv2, H.265) | 90+ days | Archive, rare access |

---

## 🎮 User Feedback Loop

### "This Wasn't Part of My Project"

**UI Interactions:**

1. **Right-click traffic light** → "This process wasn't part of my project"
2. **Select process** → Mark as:
   - "This was a break (non-work)"
   - "This was work, but unrelated to current project"
   - "This WAS part of the project (false positive)"
3. **System learns** → Updates classifier weights

### Feedback Database Schema

```sql
CREATE TABLE feedback (
    id INTEGER PRIMARY KEY,
    process_id TEXT,
    process_name TEXT,
    original_classification TEXT,  -- 'work' or 'non-work'
    user_classification TEXT,      -- User's override
    actual_project TEXT,           -- If user assigned to project
    timestamp DATETIME,
    context_snapshot TEXT          -- JSON of surrounding processes
);

-- Incremental training
CREATE TABLE classifier_weights (
    feature_name TEXT PRIMARY KEY,
    weight REAL,
    last_updated DATETIME
);
```

### Confidence Adjustment

```python
def update_classifier(feedback):
    """Adjust weights based on user feedback"""
    if feedback.user_classification != feedback.original_classification:
        # System was wrong — adjust weights
        for feature in feedback.features:
            if feature.contributed_to_wrong_decision:
                feature.weight *= 0.9  # Reduce weight
            else:
                feature.weight *= 1.1  # Increase weight

    # Save to database
    db.save_classifier_weights(classifier_weights)
```

---

## 🚦 Traffic Light UI Spec

### Visual Design

#### Option 1: System Tray (Tkinter GUI)
```
┌─────────────────────────────────────────────────────────┐
│  [🔴] [🟡] [🔵]  ← Traffic lights in system tray        │
│   │    │    │                                          │
│   │    │    └─ Duration at pressure (blue)             │
│   │    └────── Pressure acceleration (yellow)          │
│   └─────────── RAM availability (red)                  │
└─────────────────────────────────────────────────────────┘
```

#### Option 2: CLI Prompt Integration ✅ **IMPLEMENTED**
```bash
# In shell prompt
cheta@ubuntu [●●● 9%] ~/code $

# Commands:
ram-light prompt      # Output for prompt integration
ram-light tmux-status # Output for tmux status bar
ram-light title       # Update terminal title
```

#### Option 3: AI CLI Slash Commands ✅ **IMPLEMENTED**
```
User: /ram
Bot: 🔴🟡🔵 RAM: 9% free | 0 MB/min | 0s

User: /ram-capture
Bot: 📸 Capturing 15 processes... Saved to ~/.ram-traffic-light/catalogs/

User: /ram-kill
Bot: 🛑 Killed: qwen (PID 101764, 1.1GB freed)
```

### Behavior

| State | Visual | Action |
|-------|--------|--------|
| **Green (all good)** | Lights dim, gray | Passive monitoring |
| **Yellow warning** | Yellow pulses slowly | Tooltip: "Memory pressure building" |
| **Red critical** | Red flashes | Tooltip: "CRITICAL — Capture recommended" |
| **Blue sustained** | Blue pulses | Tooltip: "Sustained pressure — auto-capture ready" |
| **Auto-capture triggered** | All lights flash | Notification: "Capturing {n} processes..." |

### Interactions

| Action | Result |
|--------|--------|
| **Left-click** | Open menu: Capture Now / Kill Top Process / Nuke All |
| **Right-click light** | "This wasn't part of my project" → outlier marking |
| **Hover** | Tooltip with top 5 memory hogs + quick actions |
| **Double-click** | Open full dashboard (temporal mindmap) |

---

## 📋 Implementation Phases (Updated)

### Phase 1: RAM Traffic Light ✅ **DONE**
- [x] Memory pressure monitor
- [x] RGB calculation (availability, acceleration, duration)
- [x] CLI status command (`ram-light status`)
- [x] Shell prompt integration (`ram-light prompt`)
- [x] tmux status bar integration (`ram-light tmux-status`)
- [x] Terminal title updates (`ram-light title`)
- [x] AI CLI slash commands (`/ram`, `/ram-capture`, `/ram-kill`)
- [ ] System tray UI (Tkinter) - OPTIONAL (CLI works everywhere)
- [ ] Manual capture trigger
- [ ] Auto-capture logic

**Next:** Test CLI integration, build auto-capture

### Phase 2: Process Cataloger
- [ ] Chrome tab capture (DevTools Protocol)
- [ ] AI CLI transcript capture (tmux integration)
- [ ] IDE state capture (VS Code extension?)
- [ ] Editor file capture
- [ ] Process classification (work vs. non-work)

### Phase 3: Temporal Association Engine
- [ ] Time-based clustering
- [ ] Clipboard correlation tracking
- [ ] File/URL overlap detection
- [ ] LLM-based project inference

### Phase 4: LLM Integration
- [ ] Work classification (ambiguous cases)
- [ ] Project metadata tagging
- [ ] Session summarization
- [ ] Outlier detection + feedback learning

### Phase 5: RAG Ingestion
- [ ] Quad-encoding pipeline
- [ ] ByteRover integration (hot)
- [ ] Graphiti integration (warm)
- [ ] MemVid integration (cold)

### Phase 6: Temporal Mindmap UI
- [ ] WebGL renderer (three.js/pixi.js)
- [ ] Infinite zoom implementation
- [ ] Color coding by similarity
- [ ] Branching navigation
- [ ] Search + filter

### Phase 7: Full Automation
- [ ] Connect all components
- [ ] Tune thresholds
- [ ] Build trust through transparency
- [ ] User testing + iteration

---

## 🔐 Privacy & Security

### Data Handling

| Data Type | Storage | Encryption | Access |
|-----------|---------|------------|--------|
| **Process metadata** | SQLite (`~/.ram-traffic-light/`) | None (local only) | User only |
| **CLI transcripts** | JSON catalogs | Optional GPG | User only |
| **Chrome tabs** | JSON catalogs | None | User only |
| **Feedback database** | SQLite | None | User only |
| **RAG vectors** | ByteRover/Graphiti/MemVid | Per-backend | User + agents |

### "We Control The Telemetry"

- **No cloud uploads** — All processing local
- **No telemetry** — System doesn't phone home
- **User owns data** — Export/delete anytime
- **Transparent operation** — Logs visible, auditable
- **Opt-in sharing** — If user wants to share anonymized data for model improvement, explicit consent required

---

## 📚 Related Projects & Integration

### User's Existing Work

| Project | Integration Opportunity |
|---------|------------------------|
| **Omni-Loop (ByteRover/Graphiti/MemVid)** | Use as RAG backend, quad-encoding |
| **My-Brain-Is-Full-Crew** | Librarian/Sorter agents for auto-association |
| **SpaceVibe concept** | Tab workspace management → auto-capture trigger |
| **Omniedge research** | Agent orchestration patterns |
| **Agent Swarm Architecture** | ZeroClaw for lightweight classification tasks |

### Off-the-Shelf Components

| Component | Product | Why |
|-----------|---------|-----|
| **Process Monitoring** | psutil (Python) | Cross-platform, mature |
| **Chrome Integration** | Chrome DevTools Protocol | Full tab control |
| **CLI Capture** | tmux capture-pane | Terminal session access |
| **Vector DB** | Chroma / SQLite-vec | Low memory, Python integration |
| **LLM (Local)** | Ollama (Qwen-7B) | Fast, free, private |
| **LLM (Cloud)** | OpenRouter free tier | Cascade when local insufficient |
| **UI Framework** | Tkinter (simple) / Electron (fancy) | Tradeoff: RAM vs. polish |

---

## 🎯 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **RAM freed per capture** | 2-4GB | Before/after comparison |
| **Time to associate 75 tabs** | <30 seconds | Benchmark test |
| **Project association accuracy** | >85% | User feedback validation |
| **False positive rate (work/non-work)** | <10% | User corrections |
| **User trust (auto-capture enabled)** | Week 3+ | Usage telemetry |
| **Reduction in "lost" research** | >50% | User survey |
| **RAG retrieval accuracy** | >90% relevant | Test queries |

---

## 🏴‍☠️ Captain's Notes

This is **big**. Like, "digitize yer entire intellectual life" big.

**What makes this different:**
1. **RAM pressure as trigger** — No scheduling, no "when" — it runs when ye need it
2. **CLI prompt capture** — Not just "what file" but "what was asked" (critical for AI workflows)
3. **Temporal association** — "Ye didn't open that notepad for no reason"
4. **User feedback loop** — System learns what's work vs. break
5. **Quad-encoding** — Best-in-class RAG retrieval
6. **We control the telemetry** — Not Microsoft, not Google — US

**But:** Don't boil the ocean. Start with:
1. Traffic light monitor (done!)
2. Chrome tab capture + simple classification
3. Manual project association
4. Prove value, then expand

**Next action:** Build the Tkinter UI for the traffic light. Make it visible, make it useful, make it smoke when ye're about to OOM.

---

*Sláinte!* 🏴‍☠️
