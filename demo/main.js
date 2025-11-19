import { createAgentClient } from '/MCPBrowserClient.js';

const iterationsInput = document.getElementById('iterations');
const iterationsDisplay = document.getElementById('iterationsDisplay');
const loadingDiv = document.getElementById('loading');
const runButton = document.getElementById('runSimulation');
const selfCallButton = document.getElementById('selfCall');
const modal = document.getElementById('resultModal');
const resultContent = document.getElementById('resultContent');
const closeModalButton = document.getElementById('closeModalButton');
const asyncTaskButton = document.getElementById('startAsyncTask');
const asyncHistory = document.getElementById('asyncHistory');
const asyncTaskEntries = new Map();

const STATUS_TOOL = 'status';
const SIMULATION_TOOL = 'run_simulation';
const ASYNC_TASK_TOOL = 'demo_async_task';
const demoClient = createAgentClient('/mcps/demo/mcp');
const simulatorClient = createAgentClient('/mcps/simulator/mcp');

iterationsInput.addEventListener('input', function () {
    iterationsDisplay.textContent = this.value;
});

function extractTextFromResult(result) {
    const content = Array.isArray(result?.content) ? result.content : [];
    const textBlock = content.find(item => item?.type === 'text' && typeof item.text === 'string');
    return textBlock ? textBlock.text : '';
}

function parseJsonSafe(text) {
    if (typeof text !== 'string') return null;
    const trimmed = text.trim();
    if (!trimmed) return null;
    try {
        return JSON.parse(trimmed);
    } catch (_) {
        return null;
    }
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function showResult(html) {
    resultContent.innerHTML = html;
    modal.classList.add('active');
}

function closeModal() {
    modal.classList.remove('active');
}

function variantStyles(variant) {
    const styles = {
        running: { background: '#ebf8ff', color: '#2c5282' }, // blue
        pending: { background: '#fffaf0', color: '#b7791f' }, // yellow
        success: { background: '#e6fffa', color: '#2f855a' }, // green
        error: { background: '#fff5f5', color: '#c53030' },   // red
        info: { background: '#edf2ff', color: '#4c51bf' }
    };
    return styles[variant] || styles.info;
}

function formatStatusLabel(status) {
    if (typeof status !== 'string' || !status.length) return 'Running';
    return status.slice(0, 1).toUpperCase() + status.slice(1);
}

function statusVariant(status) {
    const normalized = typeof status === 'string' ? status.toLowerCase() : '';
    if (normalized === 'completed' || normalized === 'success') return 'success';
    if (normalized === 'failed' || normalized === 'error') return 'error';
    if (normalized === 'running' || normalized === 'queued') return 'running';
    if (normalized === 'pending') return 'pending';
    return 'info';
}

function getOrCreateAsyncTaskEntry(taskId) {
    if (!taskId || !asyncHistory) {
        return null;
    }
    if (asyncTaskEntries.has(taskId)) {
        return asyncTaskEntries.get(taskId);
    }
    const empty = asyncHistory.querySelector('.async-history-empty');
    if (empty) {
        empty.remove();
    }
    const wrapper = document.createElement('div');
    wrapper.className = 'async-history-item';
    wrapper.dataset.taskId = taskId;
    const header = document.createElement('div');
    header.className = 'async-task-header';
    const title = document.createElement('h4');
    title.textContent = `Task ${taskId}`;
    const statusBadge = document.createElement('span');
    statusBadge.className = 'async-task-status';
    header.append(title, statusBadge);
    const output = document.createElement('p');
    output.className = 'async-task-output';
    wrapper.append(header, output);
    asyncHistory.prepend(wrapper);
    const entry = { card: wrapper, statusBadge, output };
    asyncTaskEntries.set(taskId, entry);
    return entry;
}

function updateAsyncTaskEntry(taskId, status, message, variant) {
    if (!taskId) return;
    const entry = getOrCreateAsyncTaskEntry(taskId);
    if (!entry) return;
    const resolvedVariant = variant || statusVariant(status);
    const styles = variantStyles(resolvedVariant);
    entry.statusBadge.textContent = formatStatusLabel(status);
    entry.statusBadge.style.background = styles.background;
    entry.statusBadge.style.color = styles.color;
    entry.output.textContent = message || '';
}

function renameAsyncTaskEntry(oldId, newId) {
    if (!oldId || !newId || oldId === newId) {
        return newId || oldId;
    }
    const entry = asyncTaskEntries.get(oldId);
    if (!entry) {
        return newId;
    }
    asyncTaskEntries.delete(oldId);
    asyncTaskEntries.set(newId, entry);
    entry.card.dataset.taskId = newId;
    return newId;
}

async function selfCall() {
    loadingDiv.classList.add('active');
    selfCallButton.disabled = true;

    try {
        const result = await demoClient.callTool(STATUS_TOOL, {});
        const text = extractTextFromResult(result) || '';
        const data = parseJsonSafe(text);
        const pretty = data ? JSON.stringify(data, null, 2) : (text || 'No status payload.');
        const html = `
            <div style="padding: 20px;">
                <h2 style="color: #667eea; margin-bottom: 15px;">🔄 Self Call Result</h2>
                <div style="background: #f7f7f7; padding: 15px; border-radius: 8px;">
                    <pre style="white-space: pre-wrap; word-wrap: break-word;">${escapeHtml(pretty)}</pre>
                </div>
                <p style="margin-top: 15px; color: #666; font-size: 0.9em;">
                    Response from the "demo" agent
                </p>
            </div>
        `;
        showResult(html);
    } catch (error) {
        console.error('Self call error:', error);
        showResult(`<div style="color: red;">
            <h2>Error!</h2>
            <p>An error occurred during self call: ${error.message}</p>
        </div>`);
    } finally {
        loadingDiv.classList.remove('active');
        selfCallButton.disabled = false;
    }
}

async function runSimulation() {
    const iterations = parseInt(iterationsInput.value, 10);

    if (iterations < 1) {
        alert('Number of iterations must be at least 1');
        return;
    }

    loadingDiv.classList.add('active');
    runButton.disabled = true;

    try {
        const result = await simulatorClient.callTool(SIMULATION_TOOL, { iterations });
        const text = extractTextFromResult(result);
        const payload = parseJsonSafe(text);
        let html;
        if (payload && typeof payload === 'object') {
            if (payload.html) {
                html = payload.html;
            } else {
                html = `<pre style="white-space: pre-wrap;">${escapeHtml(JSON.stringify(payload, null, 2))}</pre>`;
            }
        } else if (typeof text === 'string' && text.trim()) {
            html = text;
        } else {
            html = '<p>No content.</p>';
        }
        showResult(html);
    } catch (error) {
        console.error('Error:', error);
        showResult(`<div style="color: red;">
            <h2>Error!</h2>
            <p>An error occurred while running the simulation: ${error.message}</p>
        </div>`);
    } finally {
        loadingDiv.classList.remove('active');
        runButton.disabled = false;
    }
}

function handleAsyncTaskResult(task) {
    if (!task || !task.id) {
        return;
    }
    const status = typeof task.status === 'string' ? task.status.toLowerCase() : 'unknown';
    if (status === 'pending') {
        updateAsyncTaskEntry(task.id, 'pending', 'Task queued. Waiting to start...', 'pending');
        return;
    }
    if (status === 'running') {
        updateAsyncTaskEntry(task.id, 'running', 'Task is running...', 'running');
        return;
    }
    if (status === 'completed') {
        const output = extractTextFromResult(task.result) || 'Task completed without output.';
        updateAsyncTaskEntry(task.id, 'completed', output, 'success');
        return;
    }
    if (status === 'failed') {
        const message = task.error || 'Task failed.';
        updateAsyncTaskEntry(task.id, 'failed', message, 'error');
        return;
    }
    updateAsyncTaskEntry(task.id, status || 'unknown', 'Task status updated.', 'info');
}

async function startAsyncTask() {
    if (!asyncTaskButton) return;
    const placeholderId = `pending-${Date.now()}`;
    updateAsyncTaskEntry(placeholderId, 'pending', 'Task started...', 'pending');
    try {
        const result = await demoClient.callTool(ASYNC_TASK_TOOL, {});
        const taskId = renameAsyncTaskEntry(placeholderId, result?.metadata?.taskId || placeholderId);
        handleAsyncTaskResult({
            id: taskId,
            status: result?.metadata?.status || 'completed',
            result: { content: result.content },
            error: null
        });
    } catch (error) {
        console.error('Async task error:', error);
        if (error?.task) {
            const taskId = renameAsyncTaskEntry(placeholderId, error.task.id || placeholderId);
            handleAsyncTaskResult({ ...error.task, id: taskId });
        } else {
            updateAsyncTaskEntry(placeholderId, 'failed', error?.message || 'Task failed.', 'error');
        }
    }
}

runButton.addEventListener('click', () => { void runSimulation(); });
selfCallButton.addEventListener('click', () => { void selfCall(); });
if (asyncTaskButton) {
    asyncTaskButton.addEventListener('click', () => { void startAsyncTask(); });
}
closeModalButton.addEventListener('click', closeModal);

window.addEventListener('click', (event) => {
    if (event.target === modal) {
        closeModal();
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        closeModal();
    }
});
