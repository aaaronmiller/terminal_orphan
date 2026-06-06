# 🧠 RAM-Pressure Triggered Context Capture System

**PRD Version:** 0.2  
**Date:** March 29, 2026  
**Status:** Vision → Requirements Gathering  
**Inspired By:** User's "digitize my life" vision + existing Omni-Loop architecture

---

## 🎯 Executive Summary

A **RAM-pressure triggered autonomous context capture system** that:
1. Monitors memory pressure (availability + acceleration + duration)
2. **Auto-stops and catalogs processes** (Chrome, CLI, IDE, etc.)
3. Captures **CLI prompts + outputs**, **Chrome AI conversations**, **IDE state**
4. Auto-associates resources to projects via LLM + temporal rules
5. Deduplicates, categorizes, and ingests into RAG
6. Presents captured projects via temporal mindmap interface (Hyperland/Niri-inspired)
7. **User feedback loop** — grade classification quality, system learns

**Core Insights:**
- RAM pressure = "ye've been hoarding too much good shit, time to organize it"
- CLI prompts + Chrome AI tabs = **critical context** (not just "what file" but "what was asked")
- Temporal association = "ye didn't open that notepad for no reason — ye were saving shit from clipboard"
- User grading = "this wasn't part of the project" → trains outlier detection
- **We control the telemetry** — not Microsoft Copilot working ON us, but working FOR us

---

## 🚦 Traffic Light Memory Monitor

### Three Metrics (RGB Model)

| Light | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| **🔴 Red** | RAM Availability | <20% free | **Auto-stop + catalog processes** |
| **🟡 Yellow** | RAM Pressure Acceleration | d(RAM)/dt > 100MB/min | Pre-warn, prepare to capture |
| **🔵 Blue** | Duration at Pressure | >10min sustained | Trigger auto-capture |

### Visual Design

```
┌─────────────────────────────────────────────────────────┐
│  [🔴] [🟡] [🔵]  ← Traffic lights in system tray        │
│   │    │    │                                          │
│   │    │    └─ Duration at pressure (blue)             │
│   │    └────── Pressure acceleration (yellow)          │
│   └─────────── RAM availability (red)                  │
└─────────────────────────────────────────────────────────┘
```

**Behavior:**
- **Green (all good):** Lights dim, minimal visibility
- **Yellow warning:** Lights pulse slowly
- **Red critical:** Lights flash, smoke animation (if enabled)
- **Click light:** Manual trigger (kill processes / capture now / nuke)
- **Hover:** Tooltip with top memory hogs + quick actions
- **Right-click:** "This wasn't part of my project" — marks process as outlier

### Auto-Stop + Catalog System

**When Red Light Triggers:**

```python
# auto-cataloger.py

class ProcessCataloger:
    """Captures process state for later resume + project association"""

    def __init__(self):
        self.capture_rules = {
            'chrome': self._capture_chrome,
            'code': self._capture_vscode,
            'nvim': self._capture_editor,
            'notepad': self._capture_notepad,
            'notepad++': self._capture_notepad,
            'python': self._capture_cli,
            'node': self._capture_cli,
            'claude': self._capture_ai_cli,
            'qwen': self._capture_ai_cli,
            'opencode': self._capture_ai_cli,
            'openclaw': self._capture_ai_cli,
        }

    def catalog_all(self):
        """Capture all processes before stopping"""
        catalog = {
            'timestamp': datetime.now().isoformat(),
            'trigger': 'memory_pressure',
            'processes': {}
        }

        for proc in self._get_user_processes():
            proc_type = self._classify_process(proc)
            if proc_type in self.capture_rules:
                capture = self.capture_rules[proc_type](proc)
                catalog['processes'][proc.pid] = capture

        return catalog

    def _capture_chrome(self, proc):
        """Capture Chrome tabs + AI conversation state"""
        tabs = []
        for tab in chrome.get_all_tabs():
            tab_data = {
                'url': tab.url,
                'title': tab.title,
                'favicon': tab.favicon_url,

                # AI conversation capture
                'is_ai_conversation': self._is_ai_site(tab.url),
                'conversation_transcript': self._capture_ai_transcript(tab) if self._is_ai_site(tab.url) else None,

                # Temporal context
                'opened_at': tab.created_time,
                'last_active': tab.last_accessed,
                'time_on_tab': tab.last_accessed - tab.created_time,
            }
            tabs.append(tab_data)

        return {
            'type': 'chrome',
            'pid': proc.pid,
            'tab_count': len(tabs),
            'estimated_ram': len(tabs) * 50,  # ~50MB/tab
            'tabs': tabs,
            'can_resume': True,
        }

    def _capture_ai_cli(self, proc):
        """Capture AI CLI sessions (Claude Code, Qwen, etc.)"""
        # Get session from tmux/screen
        session = self._get_tmux_session(proc)

        # Capture full transcript with prompts
        transcript = []
        for line in session.get_lines():
            if self._is_user_prompt(line):
                transcript.append({
                    'type': 'user_prompt',
                    'content': line,
                    'timestamp': line.timestamp,
                })
            elif self._is_ai_response(line):
                transcript.append({
                    'type': 'ai_response',
                    'content': line,
                    'timestamp': line.timestamp,
                    'tokens_estimated': len(line.split()) * 1.3,
                })

        # LLM summarizes the session
        session_summary = self._llm_summarize_session(transcript)

        return {
            'type': 'ai_cli',
            'pid': proc.pid,
            'command': proc.cmdline(),
            'session_name': session.name,
            'transcript': transcript,
            'summary': session_summary,
            'working_directory': proc.cwd(),
            'can_resume': True,
            'resume_command': f"{proc.name()} --continue",
        }

    def _capture_vscode(self, proc):
        """Capture VS Code state"""
        workspace = self._get_vscode_workspace(proc)
        open_files = self._get_open_files(proc)
        terminal_history = self._get_terminal_history(proc)

        # LLM infers project from open files
        project_inference = self._llm_infer_project(open_files, terminal_history)

        return {
            'type': 'ide',
            'pid': proc.pid,
            'workspace': workspace,
            'open_files': open_files,
            'terminal_history': terminal_history,
            'project_inference': project_inference,
            'can_resume': True,
        }

    def _capture_notepad(self, proc):
        """Capture notepad state + infer association"""
        open_files = self._get_open_files(proc)

        # Temporal association: what was user doing before opening notepad?
        context = self._get_temporal_context(proc.start_time())

        return {
            'type': 'editor',
            'pid': proc.pid,
            'open_files': open_files,
            'temporal_context': context,
            'inferred_association': self._infer_notepad_purpose(context),
        }
```

---

## 📋 Process Classification System

### Work vs. Non-Work Detection

| Process Type | Assumed Purpose | Auto-Capture | User Override |
|--------------|-----------------|--------------|---------------|
| **Chrome (AI sites)** | Work | ✅ Full transcript | "This was a break" |
| **Chrome (GitHub, SO)** | Work | ✅ URL + context | "This was a break" |
| **Chrome (YouTube)** | Ambiguous | ⚠️ URL only, flag | "This was research" / "This was a break" |
| **Chrome (Spotify)** | Non-work | ❌ Skip | "This was part of research" |
| **CLI (AI tools)** | Work | ✅ Full session | N/A |
| **CLI (build tools)** | Work | ✅ Command + output | N/A |
| **IDE (VS Code, etc.)** | Work | ✅ Full state | N/A |
| **Notepad/Text Editor** | Work (assumed) | ✅ File + context | "This was personal" |
| **Video Player** | Ambiguous | ⚠️ File name only | "This was research" / "This was a break" |
| **Music Player** | Non-work | ❌ Skip | "This was part of workflow" |

### Outlier Detection + User Feedback

```python
# outlier-tracker.py

class OutlierTracker:
    """Tracks user classifications to improve auto-detection"""

    def __init__(self):
        self.feedback_db = SQLiteDatabase("~/.context-capture/feedback.db")
        self.model = self._load_classifier_model()

    def record_feedback(self, process_id, was_work, actual_project=None):
        """User marks process as work/non-work + assigns project"""
        self.feedback_db.insert({
            'process_id': process_id,
            'was_work': was_work,
            'actual_project': actual_project,
            'timestamp': datetime.now(),
        })

        # Retrain model incrementally
        self._incremental_train()

    def classify_process(self, proc):
        """Predict if work/non-work + confidence"""
        features = self._extract_features(proc)
        prediction = self.model.predict(features)

        return {
            'is_work': prediction['is_work'],
            'confidence': prediction['confidence'],
            'suggested_project': prediction['project'],
            'is_outlier': prediction['confidence'] < 0.7,  # Low confidence = outlier
        }

    def _extract_features(self, proc):
        """Features for classification"""
        return {
            'process_name': proc.name(),
            'start_time': proc.start_time(),
            'duration': proc.duration(),
            'preceding_processes': self._get_preceding_processes(proc),
            'clipboard_correlation': self._check_clipboard_correlation(proc),
            'time_of_day': proc.start_time().hour,
            'day_of_week': proc.start_time().weekday(),
        }
```

---

## 🔗 Temporal Association Engine

### "Ye Didn't Open That Notepad For No Reason"

```python
# temporal-associator.py

class TemporalAssociator:
    """Associates processes based on temporal proximity + context"""

    def __init__(self):
        self.time_window = timedelta(minutes=10)

    def associate(self, processes):
        """Group processes into projects based on time + context"""
        # Sort by start time
        sorted_procs = sorted(processes, key=lambda p: p.start_time())

        projects = []
        current_project = None

        for proc in sorted_procs:
            classification = self.outlier_tracker.classify_process(proc)

            # Skip non-work
            if not classification['is_work']:
                continue

            # Check if this belongs to current project
            if current_project is None:
                current_project = self._start_project(proc, classification)
            elif self._belongs_to_project(proc, current_project):
                current_project['processes'].append(proc)
            else:
                # Start new project
                projects.append(current_project)
                current_project = self._start_project(proc, classification)

        if current_project:
            projects.append(current_project)

        return projects

    def _belongs_to_project(self, proc, project):
        """Check if process belongs to project"""
        # Temporal proximity
        time_diff = proc.start_time() - project['last_activity']
        if time_diff > self.time_window:
            return False

        # Context correlation
        if self._shares_context(proc, project):
            return True

        # Clipboard correlation
        if self._shares_clipboard(proc, project):
            return True

        return False

    def _shares_context(self, proc, project):
        """Check if processes share context (files, URLs, etc.)"""
        for existing_proc in project['processes']:
            if self._files_overlap(proc, existing_proc):
                return True
            if self._urls_related(proc, existing_proc):
                return True
        return False

    def _shares_clipboard(self, proc, project):
        """Check if clipboard was shared between processes"""
        clipboard_time = self._get_clipboard_time()
        proc_start = proc.start_time()

        # If clipboard was copied within 2min before opening this process
        if abs((proc_start - clipboard_time).total_seconds()) < 120:
            # Check if any process in project has correlated content
            for existing_proc in project['processes']:
                if self._clipboard_matches_content(existing_proc):
                    return True

        return False
```

### Implementation

```python
# ram-traffic-light.py

class MemoryPressureMonitor:
    def __init__(self):
        self.history = []  # Last 60 readings (1/min)
        self.thresholds = {
            'availability_critical': 0.20,  # 20% free
            'availability_warning': 0.30,   # 30% free
            'acceleration_threshold': 100,  # MB/min
            'duration_threshold': 600,      # 10 min in seconds
        }

    def get_pressure_metrics(self):
        """Calculate RGB values"""
        ram = psutil.virtual_memory()

        # R: Availability (inverted - low RAM = high red)
        availability = ram.available / ram.total
        red = int(255 * (1 - availability))

        # G: Acceleration (derivative)
        if len(self.history) >= 2:
            accel = (ram.used - self.history[-1]) / 60  # MB/sec
            yellow = min(255, int(accel * 2.55))
        else:
            yellow = 0

        # B: Duration at pressure
        duration = self._calculate_duration_at_pressure()
        blue = min(255, int(duration / 600 * 255))  # Max at 10min

        self.history.append(ram.used)
        return {'red': red, 'yellow': yellow, 'blue': blue}

    def should_trigger_capture(self):
        """Decision logic for auto-capture"""
        ram = psutil.virtual_memory()
        availability = ram.available / ram.total

        # Check all three conditions
        low_ram = availability < self.thresholds['availability_warning']
        high_accel = self._get_acceleration() > self.thresholds['acceleration_threshold']
        sustained = self._calculate_duration_at_pressure() > self.thresholds['duration_threshold']

        # Trigger if: (low RAM + sustained) OR (low RAM + high accel + sustained/2)
        return (low_ram and sustained) or (low_ram and high_accel and sustained/2)
```

---

## 📸 Chrome Tab Snapshot System

### Problem
75 open tabs = ~3-5GB RAM. Most are "good shit I'll get back to."

### Solution
Auto-snapshot with intelligent resume:

```python
# chrome-tab-capture.py

class ChromeTabManager:
    def __init__(self):
        self.session_file = "~/.chrome-sessions/{timestamp}.json"

    def snapshot_tabs(self, trigger_reason="memory_pressure"):
        """Capture all open tabs + metadata"""
        tabs = []

        for window in chrome.windows():
            for tab in window.tabs():
                tab_data = {
                    'url': tab.url,
                    'title': tab.title,
                    'favicon': tab.favicon_url,
                    'timestamp': datetime.now().isoformat(),
                    'window_id': window.id,
                    'position': tab.index,

                    # Smart categorization
                    'site_type': self._categorize_url(tab.url),
                    'content_preview': self._fetch_preview(tab.url),

                    # For AI conversations - extract conversation ID
                    'conversation_id': self._extract_conversation_id(tab.url),

                    # For YouTube - extract video ID + timestamp
                    'youtube_video_id': self._extract_youtube_id(tab.url),
                    'youtube_timestamp': self._extract_youtube_time(tab.url),
                }
                tabs.append(tab_data)

        # Save session
        session = {
            'trigger': trigger_reason,
            'tab_count': len(tabs),
            'estimated_ram_freed': len(tabs) * 50,  # ~50MB/tab
            'tabs': tabs
        }

        with open(self.session_file, 'w') as f:
            json.dump(session, f)

        return session

    def _categorize_url(self, url):
        """Smart URL categorization"""
        if 'claude.ai' in url or 'chat.openai.com' in url:
            return 'ai_conversation'
        elif 'youtube.com' in url:
            return 'youtube_video'
        elif 'github.com' in url:
            return 'code_repository'
        elif 'stackoverflow.com' in url:
            return 'technical_reference'
        elif 'reddit.com' in url:
            return 'discussion'
        else:
            return 'general'

    def resume_session(self, session_file, selective=True):
        """Restore tabs, optionally filtered by project"""
        with open(session_file) as f:
            session = json.load(f)

        if selective:
            # Group by project (LLM auto-associated)
            projects = self._group_tabs_by_project(session['tabs'])

            # Present to user for selection
            selected = self._show_project_picker(projects)

            # Open only selected
            for tab in selected:
                chrome.open_tab(tab['url'])
        else:
            # Open all (OG session buddy style)
            for tab in session['tabs']:
                chrome.open_tab(tab['url'])
```

### Smart Tab Features

| Site Type | Capture | Resume As |
|-----------|---------|-----------|
| **AI Conversations** | URL + conversation ID | Link back to conversation (persistent if saved) |
| **YouTube** | Video ID + timestamp | Timestamped link |
| **GitHub** | Repo + commit SHA | Repo link + code context |
| **Stack Overflow** | Question + accepted answer | Summary + link |
| **General Articles** | Readability-mode text + URL | Summary card + link |

---

## 🗂️ Project Auto-Association Agent

### The Vision
Instead of 75 tabs to sort → 15 tabs (outliers) + 5 auto-created projects

### Architecture

```python
# project-association-agent.py

class ProjectAssociator:
    def __init__(self):
        self.llm = "qwen-7b-local"  # Fast, cheap
        self.rag = existing_rag_system

    def associate_tabs_to_projects(self, tabs):
        """LLM auto-associates tabs to projects"""

        # Group by obvious signals first
        groups = self._precluster_tabs(tabs)

        # LLM analyzes each group
        projects = []
        for group in groups:
            analysis = self.llm.analyze(f"""
                Analyze these {len(group)} tabs and determine:
                1. Is this a coherent project/topic?
                2. What should this project be named?
                3. What's the goal/intent?
                4. Related Obsidian files?
                5. Related VS Code files/folders?

                Tabs:
                {json.dumps(group, indent=2)}
            """)

            if analysis['is_coherent_project']:
                projects.append({
                    'name': analysis['project_name'],
                    'goal': analysis['goal'],
                    'tabs': group,
                    'related_obsidian': analysis['obsidian_files'],
                    'related_vscode': analysis['vscode_files'],
                    'confidence': analysis['confidence'],
                })

        # Outliers (not associated)
        outliers = [tab for tab in tabs if not self._is_associated(tab, projects)]

        return projects, outliers

    def _precluster_tabs(self, tabs):
        """Fast pre-clustering by domain/time"""
        # Group by:
        # 1. Same domain (github.com/user/repo)
        # 2. Same time window (opened within 10min)
        # 3. Similar title keywords
        pass
```

### Project Data Structure

```json
{
  "project_id": "uuid",
  "name": "LLM-Generated Name",
  "created": "2026-03-29T18:30:00Z",
  "trigger": "memory_pressure_85%",
  "goal": "User's intent (LLM inferred)",

  "resources": {
    "chrome_tabs": [
      {
        "url": "https://claude.ai/chat/abc123",
        "title": "Agent Architecture Discussion",
        "type": "ai_conversation",
        "captured_at": "2026-03-29T18:30:00Z",
        "summary": "Discussed MCP Gateway + ZeroClaw architecture"
      }
    ],
    "obsidian_files": [
      {
        "path": "chetaz/agent-swarm-architecture.md",
        "last_modified": "2026-03-29T17:45:00Z",
        "relevance": "Primary spec document"
      }
    ],
    "vscode_state": {
      "workspace": "/home/cheta/code/switchboard-tui",
      "open_files": ["src/main.rs", "src/ui.rs"],
      "terminal_history": ["cargo build", "cargo run"]
    },
    "downloads": [
      {
        "file": "~/Downloads/zeroclaw-whitepaper.pdf",
        "source_url": "https://zeroclaw.io/paper.pdf",
        "downloaded_at": "2026-03-29T18:15:00Z",
        "associated_project": "agent-swarm"
      }
    ],
    "clipboard_history": [
      {
        "content": "sha256:abc123...",
        "captured_at": "2026-03-29T18:20:00Z",
        "context": "Copied during GitHub research"
      }
    ]
  },

  "llm_analysis": {
    "summary": "User is building an AI agent swarm with RAM-aware architecture",
    "key_concepts": ["ZeroClaw", "MCP Gateway", "Switchboard TUI", "RAM optimization"],
    "related_projects": ["switchboard-fork", "ramwatch-daemon"],
    "suggested_next_steps": [
      "Build MCP Gateway prototype",
      "Test ZeroClaw with OpenRouter",
      "Document session recycling patterns"
    ]
  },

  "status": "active" | "archived" | "abandoned"
}
```

---

## 🌐 Temporal Mindmap Interface (Hyperland/Niri-Inspired)

### The Vision
Infinite zoomable 2D space (horizontal + vertical), resources arranged temporally, branching like a mindmap, color-coded by similarity.

### Interface Spec

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│    [Project A] ──► [Tab 1] ──► [Obsidian]                      │
│         │              │                                        │
│         │              └─► [YouTube] ──► [Related Project]     │
│         │                                                       │
│         └─► [Tab 2] ──► [Download]                             │
│                                                                 │
│    [Project B] ──► [VS Code] ──► [GitHub]                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
      ▲              ▲              ▲
   -30min         -15min          Now
   (older)                      (current)
```

### Features

| Feature | Description |
|---------|-------------|
| **Infinite Zoom** | Zoom from bird's-eye (all projects) to individual tabs |
| **Temporal Layout** | X-axis = time, Y-axis = project clusters |
| **Color Coding** | Similar resources = similar colors (LLM-determined) |
| **Branching** | Click resource → branches to related resources |
| **Search** | Fuzzy search highlights matching nodes |
| **Filter** | Filter by type (tabs, files, downloads) or project |
| **Export** | Export project as markdown bundle |

### Tech Stack

- **Renderer:** WebGL (three.js or pixi.js)
- **Backend:** Python + FastAPI
- **Data:** SQLite (projects) + Chroma (vectors for similarity)
- **Integration:** Switchboard TUI (shared memory with ramwatch)

---

## 🔄 RAG Ingestion Pipeline

### Everything Gets Chunked + Indexed

```python
# rag-ingest.py

class ProjectIngester:
    def __init__(self):
        self.rag = existing_rag_system
        self.chunker = multi_strategy_chunker  # Quad encoding

    def ingest_project(self, project):
        """Ingest all project resources into RAG"""

        for tab in project['chrome_tabs']:
            content = self._fetch_tab_content(tab['url'])
            chunks = self.chunker.chunk(content)
            self.rag.add({
                'type': 'chrome_tab',
                'project_id': project['id'],
                'chunks': chunks,
                'metadata': tab
            })

        for obsidian_file in project['obsidian_files']:
            content = open(obsidian_file['path']).read()
            chunks = self.chunker.chunk(content)
            self.rag.add({
                'type': 'obsidian_file',
                'project_id': project['id'],
                'chunks': chunks,
                'metadata': obsidian_file
            })

        # ... same for VS Code, downloads, clipboard
```

---

## 🎯 Trigger Logic (RAM Pressure → Action)

```python
# trigger-decider.py

class TriggerDecider:
    def __init__(self):
        self.monitor = MemoryPressureMonitor()
        self.capturer = ChromeTabManager()
        self.associator = ProjectAssociator()

    def check_and_act(self):
        """Main loop - check every 30 seconds"""
        metrics = self.monitor.get_pressure_metrics()

        # Green: Do nothing
        if metrics['red'] < 128 and metrics['yellow'] < 128 and metrics['blue'] < 128:
            return

        # Yellow warning: Pre-capture (don't close yet)
        if metrics['yellow'] >= 128:
            self._notify_user("Memory pressure building. Prepare to capture.")
            self.capturer.snapshot_tabs(pre_capture=True)

        # Red critical: Capture + close
        if metrics['red'] >= 200:
            session = self.capturer.snapshot_tabs()
            projects, outliers = self.associator.associate_tabs_to_projects(session['tabs'])

            # Auto-close non-outlier tabs
            for project in projects:
                for tab in project['tabs']:
                    chrome.close_tab(tab['id'])

            # Notify user
            self._notify_user(f"""
                Captured {len(projects)} projects:
                {[p['name'] for p in projects]}

                {len(outliers)} outlier tabs preserved.
                RAM freed: {session['estimated_ram_freed']}MB
            """)

        # Blue sustained: Full ingest
        if metrics['blue'] >= 200:
            self._trigger_full_ingest()
```

---

## 📚 Related Existing Work

### User's Existing Docs

| Document | Relevance |
|----------|-----------|
| `Autodidactic Omni-Loop system using ByteRover, Graphiti, and MemVid..md` | **Quad encoding**, sleep-time compute, memory hierarchy (Hot/Warm/Cold) |
| `SpaceVibe.md` | Hyperland-style interface concepts |
| `Omniedge.md` | Edge-based knowledge graph |
| `memory prd - super rag.md` | RAG architecture |
| `My-Brain-Is-Full-Crew/` | Agent roles (Librarian, Sorter, Connector) |

### Integration Opportunities

1. **Use Omni-Loop's Quad Encoding** for RAG ingestion
2. **Use ByteRover for Hot Memory** (active projects)
3. **Use Graphiti for Warm Memory** (project relationships)
4. **Use MemVid for Cold Memory** (archived projects)
5. **Use My-Brain-Is-Full-Crew agents** for auto-association

---

## 🚀 Implementation Phases

### Phase 1: RAM Traffic Light (Week 1) ✅ **IN PROGRESS**
- [x] Build memory pressure monitor
- [x] Calculate RGB values (availability, acceleration, duration)
- [x] Create CLI status command
- [ ] Create system tray UI (Tkinter)
- [ ] Add manual capture/kill actions
- [ ] Add auto-capture trigger

**Current Status:** CLI working, UI pending

### Phase 2: Chrome Tab Capture (Week 2)
- [ ] Build tab snapshot system
- [ ] Implement smart categorization
- [ ] Add selective resume
- [ ] Chrome DevTools Protocol integration

### Phase 3: Project Auto-Association (Week 3)
- [ ] Build LLM associator agent
- [ ] Create project data structure
- [ ] Test with real browsing sessions

### Phase 4: RAG Ingestion (Week 4)
- [ ] Integrate with existing RAG
- [ ] Add quad encoding
- [ ] Build retrieval interface

### Phase 5: Temporal Mindmap (Weeks 5-6)
- [ ] Build WebGL renderer
- [ ] Implement infinite zoom
- [ ] Add color coding + branching

### Phase 6: Full Automation (Week 7+)
- [ ] Connect trigger logic
- [ ] Tune thresholds
- [ ] Build trust through transparency

---

## 🎯 Success Metrics

| Metric | Target |
|--------|--------|
| RAM freed per capture | 2-4GB |
| Time to associate 75 tabs | <30 seconds |
| Project association accuracy | >85% |
| User trust (auto-capture enabled) | Week 3+ |
| Reduction in "lost" research | >50% |

---

## 🏴‍☠️ Captain's Notes

This is **big**. Like, "digitize yer entire intellectual life" big.

**Key innovations:**
1. **RAM pressure as trigger** — No more "when does it run?" — it runs when ye need it to
2. **Auto-association** — LLM does the boring sorting work
3. **Temporal mindmap** — Visual, spatial, intuitive
4. **Quad encoding** — Best-in-class RAG ingestion

**But:** Don't boil the ocean. Start with the traffic light + tab capture. Prove value. Then expand.

**Next action:** Build the traffic light monitor. It's small, visible, and proves the concept.

---

*Sláinte!* 🏴‍☠️
