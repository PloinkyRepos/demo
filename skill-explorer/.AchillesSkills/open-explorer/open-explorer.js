/**
 * Open Explorer Skill - Returns the file explorer URL
 */

export async function action(input, context = {}) {
    const explorerUrl = 'http://127.0.0.1:8080/explorer/index.html';

    return {
        success: true,
        message: `## File Explorer

**Open Explorer:** [${explorerUrl}](${explorerUrl})

The explorer opens directly to the **.AchillesSkills** directory where all skills are stored.`
    };
}
