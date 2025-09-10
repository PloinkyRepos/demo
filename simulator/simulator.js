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
            <h2>🎰 Rezultatele Simulării Monty Hall</h2>
            <div class="iterations-info">
                <strong>${results.iterations.toLocaleString()}</strong> iterații completate
            </div>
        </div>
        
        <div class="results-grid">
            <div class="result-card switch-card">
                <div class="strategy-label">🔄 Strategia: SCHIMBĂ</div>
                <div class="win-rate">${results.switchWinRate}%</div>
                <div class="wins-count">${results.winsWithSwitch.toLocaleString()} câștiguri</div>
            </div>
            
            <div class="result-card stay-card">
                <div class="strategy-label">🎯 Strategia: PĂSTREAZĂ</div>
                <div class="win-rate">${results.stayWinRate}%</div>
                <div class="wins-count">${results.winsWithoutSwitch.toLocaleString()} câștiguri</div>
            </div>
        </div>
        
        <div class="conclusion">
            <h3>📊 Concluzie</h3>
            <p>
                După ${results.iterations.toLocaleString()} simulări, strategia de a <span class="advantage">SCHIMBA alegerea</span> 
                a avut o rată de succes cu <span class="advantage">${switchAdvantage}%</span> mai mare decât strategia 
                de a păstra alegerea inițială.
            </p>
            <p>
                Acest lucru confirmă paradoxul Monty Hall: șansele de câștig se dublează când schimbați ușa!
                <span class="emoji">🚪➡️🚪</span>
            </p>
        </div>
        
        <div class="theoretical-note">
            <h4>📚 Notă Teoretică</h4>
            <p>
                În teorie, probabilitățile sunt:
            </p>
            <table class="stats-table">
                <thead>
                    <tr>
                        <th>Strategie</th>
                        <th>Probabilitate Teoretică</th>
                        <th>Rezultat Simulare</th>
                        <th>Diferență</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Schimbă</td>
                        <td>${theoreticalSwitch}%</td>
                        <td>${results.switchWinRate}%</td>
                        <td>${(Math.abs(results.switchWinRate - theoreticalSwitch)).toFixed(2)}%</td>
                    </tr>
                    <tr>
                        <td>Păstrează</td>
                        <td>${theoreticalStay}%</td>
                        <td>${results.stayWinRate}%</td>
                        <td>${(Math.abs(results.stayWinRate - theoreticalStay)).toFixed(2)}%</td>
                    </tr>
                </tbody>
            </table>
            <p style="margin-top: 10px;">
                Cu cât rulați mai multe iterații, cu atât rezultatele se apropie mai mult de valorile teoretice!
            </p>
        </div>
    </div>
    `;
}

function main() {
    const input = process.argv[2];
    
    if (!input) {
        console.error('Error: No input provided');
        process.exit(1);
    }
    
    try {
        const data = JSON.parse(input);
        
        if (!data.nrIteratii || typeof data.nrIteratii !== 'number') {
            throw new Error('Invalid nrIteratii parameter');
        }
        
        const results = runMontyHallSimulation(data.nrIteratii);
        const html = generateHTML(results);
        
        console.log(html);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}