#!/usr/bin/env node

function runMontyHallSimulation(iterations) {
    let winsWithSwitch = 0;
    let winsWithoutSwitch = 0;
    
    for (let i = 0; i < iterations; i++) {
        const doors = [0, 1, 2];
        const prizeDoor = Math.floor(Math.random() * 3);
        
        const initialChoice = Math.floor(Math.random() * 3);
        
        const doorsWithGoats = doors.filter(d => d !== prizeDoor && d !== initialChoice);
        const doorOpenedByHost = doorsWithGoats[Math.floor(Math.random() * doorsWithGoats.length)];
        
        const remainingDoor = doors.find(d => d !== initialChoice && d !== doorOpenedByHost);
        
        if (initialChoice === prizeDoor) {
            winsWithoutSwitch++;
        }
        
        if (remainingDoor === prizeDoor) {
            winsWithSwitch++;
        }
    }
    
    const switchWinRate = ((winsWithSwitch / iterations) * 100).toFixed(2);
    const stayWinRate = ((winsWithoutSwitch / iterations) * 100).toFixed(2);
    
    return {
        iterations,
        winsWithSwitch,
        winsWithoutSwitch,
        switchWinRate,
        stayWinRate
    };
}

function generateHTML(results) {
    const switchAdvantage = (results.switchWinRate - results.stayWinRate).toFixed(2);
    const theoreticalSwitch = "66.67";
    const theoreticalStay = "33.33";
    
    return `
    <style>
        .simulation-results {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding: 20px;
        }
        .result-header {
            text-align: center;
            margin-bottom: 30px;
        }
        .result-header h2 {
            color: #333;
            font-size: 2em;
            margin-bottom: 10px;
        }
        .iterations-info {
            color: #666;
            font-size: 1.2em;
            margin-bottom: 20px;
        }
        .results-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        .result-card {
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .switch-card {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
        }
        .stay-card {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: white;
        }
        .strategy-label {
            font-size: 1.1em;
            margin-bottom: 10px;
            opacity: 0.9;
        }
        .win-rate {
            font-size: 3em;
            font-weight: bold;
            margin: 10px 0;
        }
        .wins-count {
            font-size: 0.9em;
            opacity: 0.8;
        }
        .conclusion {
            background: #f3f4f6;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .conclusion h3 {
            color: #333;
            margin-bottom: 10px;
        }
        .conclusion p {
            color: #555;
            line-height: 1.6;
            margin-bottom: 10px;
        }
        .advantage {
            color: #10b981;
            font-weight: bold;
        }
        .theoretical-note {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
        .theoretical-note h4 {
            color: #92400e;
            margin-bottom: 10px;
        }
        .theoretical-note p {
            color: #78350f;
            line-height: 1.5;
        }
        .stats-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .stats-table th,
        .stats-table td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
        }
        .stats-table th {
            background: #f9fafb;
            font-weight: 600;
            color: #374151;
        }
        .stats-table td {
            color: #6b7280;
        }
        .emoji {
            font-size: 1.5em;
            margin: 0 5px;
        }
    </style>
    
    <div class="simulation-results">
        <div class="result-header">
            <h2>🎰 Monty Hall Simulation Results</h2>
            <div class="iterations-info">
                <strong>${results.iterations.toLocaleString()}</strong> iterations completed
            </div>
        </div>
        
        <div class="results-grid">
            <div class="result-card switch-card">
                <div class="strategy-label">🔄 Strategy: SWITCH</div>
                <div class="win-rate">${results.switchWinRate}%</div>
                <div class="wins-count">${results.winsWithSwitch.toLocaleString()} wins</div>
            </div>
            
            <div class="result-card stay-card">
                <div class="strategy-label">🎯 Strategy: STAY</div>
                <div class="win-rate">${results.stayWinRate}%</div>
                <div class="wins-count">${results.winsWithoutSwitch.toLocaleString()} wins</div>
            </div>
        </div>
        
        <div class="conclusion">
            <h3>📊 Conclusion</h3>
            <p>
                After ${results.iterations.toLocaleString()} simulations, the strategy of <span class="advantage">SWITCHING</span> 
                had a success rate <span class="advantage">${switchAdvantage}%</span> higher than the strategy 
                of keeping the initial choice.
            </p>
            <p>
                This confirms the Monty Hall paradox: your chances of winning double when you switch doors!
                <span class="emoji">🚪➡️🚪</span>
            </p>
        </div>
        
        <div class="theoretical-note">
            <h4>📚 Theoretical Note</h4>
            <p>
                In theory, the probabilities are:
            </p>
            <table class="stats-table">
                <thead>
                    <tr>
                        <th>Strategy</th>
                        <th>Theoretical Probability</th>
                        <th>Simulation Result</th>
                        <th>Difference</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Switch</td>
                        <td>${theoreticalSwitch}%</td>
                        <td>${results.switchWinRate}%</td>
                        <td>${(Math.abs(results.switchWinRate - theoreticalSwitch)).toFixed(2)}%</td>
                    </tr>
                    <tr>
                        <td>Stay</td>
                        <td>${theoreticalStay}%</td>
                        <td>${results.stayWinRate}%</td>
                        <td>${(Math.abs(results.stayWinRate - theoreticalStay)).toFixed(2)}%</td>
                    </tr>
                </tbody>
            </table>
            <p style="margin-top: 10px;">
                The more iterations you run, the closer the results get to the theoretical values!
            </p>
        </div>
    </div>
    `;
}

function readStdin() {
    return new Promise((resolve, reject) => {
        let data = '';
        process.stdin.setEncoding('utf8');
        process.stdin.on('data', chunk => {
            data += chunk;
        });
        process.stdin.on('end', () => resolve(data));
        process.stdin.on('error', reject);
    });
}

async function main() {
    let raw = '';
    try {
        raw = await readStdin();
    } catch (err) {
        console.error('Failed to read stdin:', err);
        process.exit(1);
    }

    let payload = {};
    if (raw && raw.trim()) {
        try {
            payload = JSON.parse(raw);
        } catch (err) {
            console.warn('Could not parse payload JSON, falling back to defaults:', err?.message || String(err));
        }
    }

    const maybeIterations = payload?.input?.iterations;
    const numericIterations = Number(maybeIterations);
    let iterations = 10;
    let warningHtml = '';

    if (Number.isFinite(numericIterations) && numericIterations > 0) {
        iterations = Math.floor(numericIterations);
    } else if (maybeIterations !== undefined) {
        warningHtml = '<div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 10px; margin-bottom: 20px; color: #92400e;">⚠️ Invalid parameters received. Using default of 10 iterations.</div>';
    }

    const results = runMontyHallSimulation(iterations);
    let html = generateHTML(results);
    if (warningHtml) {
        html = warningHtml + html;
    }

    const response = {
        ok: true,
        iterations,
        winsWithSwitch: results.winsWithSwitch,
        winsWithoutSwitch: results.winsWithoutSwitch,
        switchWinRate: results.switchWinRate,
        stayWinRate: results.stayWinRate,
        html
    };

    console.log(JSON.stringify(response));
}

if (require.main === module) {
    main().catch(err => {
        console.error(err?.stack || err?.message || String(err));
        process.exit(1);
    });
}
