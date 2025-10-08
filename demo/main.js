import { createAgentClient } from '/MCPBrowserClient.js';

const iterationsInput = document.getElementById('iterations');
const iterationsDisplay = document.getElementById('iterationsDisplay');
const loadingDiv = document.getElementById('loading');
const runButton = document.getElementById('runSimulation');
const selfCallButton = document.getElementById('selfCall');
const modal = document.getElementById('resultModal');
const resultContent = document.getElementById('resultContent');
const closeModalButton = document.getElementById('closeModalButton');

const STATUS_TOOL = 'status';
const SIMULATION_TOOL = 'run_simulation';
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

runButton.addEventListener('click', () => { void runSimulation(); });
selfCallButton.addEventListener('click', () => { void selfCall(); });
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
