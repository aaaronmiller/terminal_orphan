# 🏴‍☠️ Prior Art Analysis — Context Capture & Activity Tracking

**Date:** March 29, 2026  
**Research Scope:** GitHub, Reddit, Product Hunt, Academic Papers (2025-2026)  
**Goal:** Identify what exists, what we can steal, and where our unique value lies

---

## 📊 Competitive Landscape Summary

| Category | Key Players | What They Do | What They Miss | Our Edge |
|----------|-------------|--------------|----------------|----------|
| **Activity Tracking** | ActivityWatch, WakaTime | Track app/window usage, time by project | Manual project assignment, no auto-association | **Auto-associate via RAM pressure + LLM** |
| **Session Capture** | Entire CLI, Session-Context | Git-linked AI session recording | Manual triggers, Git-dependent | **Automatic, RAM-triggered, not Git-bound** |
| **Second Brain / PKM** | Remio, Mem0, Letta | Auto-capture notes, emails, meetings | Cloud-first, manual organization | **Local-first, auto-organize by project** |
| **Context Engineering** | MemGPT, LangChain, MCP | Dynamic context assembly for agents | Agent-focused, not desktop context | **Full desktop context (browser + CLI + IDE)** |
| **Tab/Session Management** | SpaceVibe, Session Buddy | Tab workspaces, crash recovery | Manual switching, no intelligence | **Auto-capture + auto-associate** |

---

## 🔍 Deep Dives

### 1. **ActivityWatch** (Open Source Time Tracker)

**What It Does:**
- Tracks active application + window title
- Browser extensions for tab tracking
- Editor plugins for coding time
- All data stored locally

**Privacy Model:** ✅ Local-first, open-source (MPL-2.0)

**What We Can Steal:**
```python
# Watcher architecture (from ActivityWatch)
class Watcher:
    def __init__(self, target='app'):
        self.target = target
        self.callback = None
    
    def start(self):
        # Watch active window
        # Watch browser tabs
        # Watch editor activity
        pass

# We can adapt for RAM-pressure triggers:
class RAMWatcher(Watcher):
    def __init__(self):
        super().__init__(target='memory')
        self.threshold = 0.85
    
    def check(self):
        if ram.available_pct < self.threshold:
            self.callback()  # Trigger capture
```

**What They Miss:**
- ❌ No automatic project association
- ❌ No AI/CLI transcript capture
- ❌ No temporal correlation ("what was open together")
- ❌ Manual categorization required

---

### 2. **Entire CLI** (Git-Linked AI Session Recorder)

**What It Does:**
- Hooks into Claude Code, Gemini, Cursor
- Captures full transcripts (prompts + responses)
- Stores on separate Git branch (`entire/checkpoints/v1`)
- Links sessions to commits

**Privacy Model:** ⚠️ Repo-based (public repo = public transcripts), auto-redaction (best-effort)

**What We Can Steal:**
```python
# Shadow branch pattern (for clean separation)
class ShadowStorage:
    def __init__(self, branch='ram-captures/v1'):
        self.branch = branch
    
    def save(self, snapshot):
        # Save to separate branch/storage
        # Keep main process clean
        pass

# Hook installation pattern
def install_hooks():
    # Inject into .claude/settings.json
    # Inject into .cursor/hooks.json
    # Auto-detect installed agents
    pass
```

**What They Miss:**
- ❌ Manual commit triggers (not automatic)
- ❌ Git-dependent (no Git = no capture)
- ❌ No RAM awareness
- ❌ No browser/IDE state capture

---

### 3. **Session-Context** (Claude Code Continuity Plugin)

**What It Does:**
- Auto-tracks file edits, todos, plans via hooks
- Survives autocompact via session markers (`<!-- session:abc123 -->`)
- Creates rolling checkpoints
- `/handoff` command for continuation prompts

**Privacy Model:** ✅ Local-only (`~/.claude/session-context/`), MIT license

**What We Can Steal:**
```python
# Session marker strategy (survives summarization)
SESSION_MARKER = "<!-- session:{} -->"

def inject_marker(session_id):
    return SESSION_MARKER.format(session_id)

# Rolling checkpoint pattern
class Checkpoint:
    def __init__(self, path='~/.ram-capture/checkpoints/'):
        self.path = path
    
    def update(self, state):
        # Overwrite current.json (rolling)
        # Keep history in handoffs/{id}.json
        pass
```

**What They Miss:**
- ❌ Claude Code only
- ❌ No browser capture
- ❌ No RAM pressure triggers
- ❌ Manual `/handoff` command

---

### 4. **Remio** (AI-Native Second Brain)

**What It Does:**
- Auto-captures notes, emails, meetings, files
- Conversational retrieval with citations (RAG)
- Proactive reviews (weekly/monthly digests)
- Local-first vector storage (SQLite/FAISS)

**Privacy Model:** ✅ Local-first, on-device processing

**What We Can Steal:**
```python
# Pipeline architecture (from Remio)
class IngestionPipeline:
    def __init__(self):
        self.watcher = FileSystemWatcher()
        self.parser = MultiFormatParser()
        self.chunker = SemanticChunker()
        self.embedder = LocalEmbedder()
        self.retriever = HybridRetriever()
    
    def process(self, doc):
        chunks = self.chunker.chunk(doc)
        embeddings = self.embedder.encode(chunks)
        self.retriever.add(chunks, embeddings)

# Citation requirement (force "cite or abstain")
def answer_with_citations(query):
    results = retriever.search(query)
    if not results:
        return "I don't have enough context to answer."
    return generate_answer(query, results, citations=results)
```

**What They Miss:**
- ❌ Cloud sync optional (privacy risk)
- ❌ Manual file ingestion (drag & drop)
- ❌ No process/CLI capture
- ❌ No RAM awareness

---

### 5. **SpaceVibe** (Tab Workspace Manager)

**What It Does:**
- Organizes tabs into project workspaces
- Switch workspaces (close current, open new)
- Local-first storage (browser localStorage)
- Sync via Chrome bookmarks

**Privacy Model:** ✅ Local-first, no account required

**What We Can Steal:**
```python
# Workspace pattern (for Chrome tab grouping)
class Workspace:
    def __init__(self, name):
        self.name = name
        self.tabs = []
    
    def save(self):
        # Save to localStorage
        pass
    
    def restore(self):
        # Close current tabs
        # Open saved tabs
        pass

# We adapt for auto-capture:
class AutoWorkspace(Workspace):
    def auto_save(self, trigger='ram_pressure'):
        # Auto-save when RAM pressure hits
        # No manual switching required
        pass
```

**What They Miss:**
- ❌ Manual workspace creation
- ❌ No auto-association
- ❌ Browser-only (no CLI/IDE capture)
- ❌ No intelligence (just tab lists)

---

### 6. **Awesome-Context-Engineering** (GitHub List)

**Key Projects Listed:**
- **Memory:** MemGPT, Mem0, Mem1, Letta
- **Frameworks:** LangChain, AutoGen, MetaGPT, Google ADK
- **Protocols:** MCP, A2A, AG-UI
- **Production:** Claude Code, OpenAI Codex, Vertex AI
- **Observability:** LangSmith, OpenTelemetry

**Key Insights:**
1. **Static prompting is dead** — Dynamic context assembly is the future
2. **Agent engineering is king (2026)** — Context lives in agent runtimes
3. **Production requires compaction** — Can't shove everything in context window
4. **Interoperability is crucial** — Use MCP, A2A, open protocols
5. **Memory isn't just vectors** — Lives in repo files (`CLAUDE.md`, `SKILL.md`)

**What We Can Steal:**
```python
# Trace-first observability (from LangSmith)
class TraceLogger:
    def __init__(self):
        self.trace_id = uuid.uuid4()
    
    def log(self, event):
        # Log plan, tool calls, memory reads/writes
        # Structured JSON for later analysis
        pass

# Memory artifacts (persistent context)
class MemoryArtifact:
    def __init__(self, path='CLAUDE.md'):
        self.path = path
    
    def update(self, content):
        # Append to repo file
        # Survives session restarts
        pass
```

---

## 🎯 What Nobody's Doing (Our Opportunity)

| Gap | Current Solutions | Our Solution |
|-----|-------------------|--------------|
| **Automatic project association** | Manual categorization (ActivityWatch, SpaceVibe) | **LLM + temporal rules** ("ye didn't open notepad for no reason") |
| **RAM pressure as trigger** | Scheduled or manual triggers | **Auto-trigger when memory critical** |
| **CLI transcript capture** | Git-linked (Entire CLI) or nothing | **tmux integration, prompt+output capture** |
| **Cross-process correlation** | Single-app focus (browser OR IDE) | **Full desktop context** (browser + CLI + IDE + files) |
| **User feedback loop** | Static classification | **System learns from corrections** ("this wasn't my project") |
| **Quad-encoding for RAG** | Standard chunking (paragraph-level) | **Word/sentence/paragraph/boundary** (Omni-Loop v3.0) |
| **We control the telemetry** | Cloud-first or optional sync | **Local-first, no cloud, user owns data** |

---

## 📋 What We're Stealing (Categorized)

### From ActivityWatch
- ✅ Watcher architecture (modular, extensible)
- ✅ Local-first storage model
- ✅ Browser extension pattern (Chrome/Firefox)

### From Entire CLI
- ✅ Shadow branch/storage pattern (clean separation)
- ✅ Hook installation (auto-detect agents)
- ✅ Secret redaction pipeline (pre-write filtering)

### From Session-Context
- ✅ Session markers (survive summarization)
- ✅ Rolling checkpoint pattern
- ✅ Pre-load hooks (before command runs)

### From Remio
- ✅ Ingestion pipeline (watcher → parser → chunker → embedder)
- ✅ Citation requirement ("cite or abstain")
- ✅ Proactive reviews (weekly digests)

### From SpaceVibe
- ✅ Workspace pattern (tab grouping)
- ✅ Local-first browser storage

### From Awesome-Context-Engineering
- ✅ Trace-first observability
- ✅ Memory artifacts (repo files)
- ✅ Context compaction techniques

---

## 🔐 Privacy Comparison

| Project | Storage | Encryption | Cloud Sync | Telemetry |
|---------|---------|------------|------------|-----------|
| **ActivityWatch** | Local SQLite | None | Optional | None |
| **Entire CLI** | Git branch | None | Yes (repo) | Optional (Posthog) |
| **Session-Context** | Local JSON | None | No | None |
| **Remio** | Local + Cloud | Optional | Yes | Yes |
| **SpaceVibe** | Browser localStorage | None | Via bookmarks | None |
| **Our System** | Local SQLite + JSON | Optional GPG | No | None ✅ |

---

## 🚀 Unique Value Proposition

**"We're building ActivityWatch meets Entire CLI meets Remio — but local-first, RAM-aware, and privacy-preserving."**

**Key Differentiators:**
1. **RAM pressure trigger** — No scheduling, runs when ye need it
2. **Full desktop context** — Browser + CLI + IDE + files
3. **Auto-association** — LLM + temporal rules, not manual
4. **User feedback loop** — System learns what's work vs. break
5. **Quad-encoding** — Best-in-class RAG retrieval
6. **We control the telemetry** — No cloud, no spies

---

## 📚 Academic/Research Insights

### Memory Palaces (UChicago Study, Jan 2026)
- **Finding:** Emotional context improves recall
- **Application:** Tag captured sessions with emotional valence (stress from RAM pressure = high priority)

### Context Engineering Bottleneck (New Stack, Jan 2026)
- **Finding:** Context window size isn't the bottleneck — **context quality** is
- **Application:** Quad-encoding + LLM metadata tagging = higher quality context

### Local-First Software (TraceMind, Mar 2026)
- **Finding:** Users willing to trade convenience for privacy
- **Application:** Emphasize "no cloud, no telemetry" in messaging

---

## 🏴‍☠️ Captain's Verdict

**Prior art is rich, but nobody's connecting these dots:**

| What Exists | What's Missing | We Fill The Gap |
|-------------|----------------|-----------------|
| Activity tracking | Auto-association | ✅ LLM + temporal rules |
| Session capture | RAM awareness | ✅ Pressure triggers |
| Second brain | CLI/process capture | ✅ Full desktop context |
| Tab workspaces | Intelligence | ✅ Auto-capture + classify |
| Context engineering | Desktop context | ✅ Browser + CLI + IDE |

**Our system is the love child of:**
- ActivityWatch's local-first tracking
- Entire CLI's session capture
- Remio's ingestion pipeline
- Omni-Loop's quad-encoding
- User's "digitize my life" vision

**Next:** Build it, test it, and may the swappiness be ever in yer favor.

---

*Sláinte!* 🏴‍☠️
