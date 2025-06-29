#!/usr/bin/env node

/**
 * Velocity Protocol Open Hub Deployment Script
 * 
 * This script deploys the openhub.lua to AO and registers it with the Zones Registry
 * following VIP-06 specifications for hub discovery.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
    // AO Network Configuration
    aos: {
        binary: 'aos',
        args: ['--relay', 'https://cu.ao-testnet.xyz', '--gateway', 'https://g8way.io']
    },
    
    // Hub Configuration
    hub: {
        name: 'velocity-openhub',
        description: 'Open Public Velocity Protocol Hub - Censorship-resistant messaging',
        kinds: [1, 3, 7], // VIP-03: text/replies, VIP-02: follows, VIP-04: reactions
        isPublic: true
    },
    
    // Registry Configuration
    registry: {
        processId: 'qrXGWjZ1qYkFK4_rCHwwKKEtgAE3LT0WJ-MYhpaMjtE', // Default registry
        autoRegister: true
    },
    
    // File paths
    files: {
        hubScript: path.join(__dirname, 'zones', 'openhub.lua'),
        deployLog: path.join(__dirname, 'deployment.log')
    }
};

class OpenHubDeployer {
    constructor() {
        this.processId = null;
        this.deploymentLog = [];
    }

    log(message) {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] ${message}`;
        this.deploymentLog.push(logEntry);
        console.log(logEntry);
    }

    async checkDependencies() {
        this.log('Checking deployment dependencies...');
        
        // Check if AOS is installed
        try {
            const { execSync } = require('child_process');
            execSync('which aos', { stdio: 'ignore' });
            this.log('✓ AOS CLI found');
        } catch (error) {
            throw new Error('AOS CLI not found. Please install AOS first: npm i -g https://get_ao.g8way.io');
        }
        
        // Check if hub script exists
        if (!fs.existsSync(CONFIG.files.hubScript)) {
            throw new Error(`Hub script not found at: ${CONFIG.files.hubScript}`);
        }
        this.log('✓ Hub script found');
        
        return true;
    }

    async deployHub() {
        this.log('Starting Velocity Protocol Open Hub deployment...');
        
        const { spawn } = require('child_process');
        
        return new Promise((resolve, reject) => {
            // Start AOS with configuration
            const aosArgs = [
                ...CONFIG.aos.args,
                '--name', CONFIG.hub.name,
                '--tag-name', 'Velocity-Hub',
                '--tag-name', 'Open-Hub'
            ];
            
            this.log(`Spawning AOS process: aos ${aosArgs.join(' ')}`);
            const aosProcess = spawn('aos', aosArgs, { 
                stdio: ['pipe', 'pipe', 'pipe'],
                shell: true 
            });
            
            let output = '';
            let processReady = false;
            
            aosProcess.stdout.on('data', (data) => {
                output += data.toString();
                
                // Look for process ID in output
                const processIdMatch = output.match(/Process (\w+) spawned/);
                if (processIdMatch && !this.processId) {
                    this.processId = processIdMatch[1];
                    this.log(`✓ Hub process spawned with ID: ${this.processId}`);
                }
                
                // Check if AOS is ready for commands
                if (output.includes('ao>') && !processReady) {
                    processReady = true;
                    this.loadHubScript(aosProcess, resolve, reject);
                }
            });
            
            aosProcess.stderr.on('data', (data) => {
                this.log(`AOS Error: ${data.toString()}`);
            });
            
            aosProcess.on('error', (error) => {
                this.log(`Failed to spawn AOS process: ${error.message}`);
                reject(error);
            });
            
            // Set timeout for deployment
            setTimeout(() => {
                if (!processReady) {
                    aosProcess.kill();
                    reject(new Error('Deployment timeout - AOS did not become ready'));
                }
            }, 30000);
        });
    }

    loadHubScript(aosProcess, resolve, reject) {
        try {
            this.log('Loading hub script into AOS process...');
            
            // Read the hub script
            const hubScript = fs.readFileSync(CONFIG.files.hubScript, 'utf8');
            
            // Send the script to AOS
            aosProcess.stdin.write(hubScript + '\n');
            
            // Wait a moment for script to load
            setTimeout(() => {
                this.log('✓ Hub script loaded');
                this.registerWithRegistry(aosProcess, resolve, reject);
            }, 2000);
            
        } catch (error) {
            this.log(`Failed to load hub script: ${error.message}`);
            reject(error);
        }
    }

    registerWithRegistry(aosProcess, resolve, reject) {
        if (!CONFIG.registry.autoRegister) {
            this.log('Auto-registration disabled, skipping registry registration');
            this.finishDeployment(aosProcess, resolve);
            return;
        }
        
        this.log(`Registering hub with registry: ${CONFIG.registry.processId}`);
        
        // Create registration message
        const registrationData = {
            type: "hub",
            description: CONFIG.hub.description,
            kinds: CONFIG.hub.kinds,
            version: "1.0",
            processId: this.processId,
            isPublic: CONFIG.hub.isPublic,
            acceptsAllEvents: true
        };
        
        const registrationCommand = `
Send({
    Target = "${CONFIG.registry.processId}",
    Action = "Register",
    Data = '${JSON.stringify(registrationData)}',
    Tags = {
        {"Data-Protocol", "Zone"},
        {"Zone-Type", "Channel"}
    }
})
`;
        
        aosProcess.stdin.write(registrationCommand + '\n');
        
        // Wait for registration to complete
        setTimeout(() => {
            this.log('✓ Registration request sent to registry');
            this.finishDeployment(aosProcess, resolve);
        }, 2000);
    }

    finishDeployment(aosProcess, resolve) {
        this.log('Hub deployment completed successfully!');
        this.log(`Process ID: ${this.processId}`);
        this.log(`Registry: ${CONFIG.registry.processId}`);
        this.log(`Supported Kinds: ${CONFIG.hub.kinds.join(', ')}`);
        this.log('Note: Hub accepts all message kinds, no rate limits');
        
        // Save deployment log
        this.saveDeploymentLog();
        
        // Keep process running or exit based on configuration
        this.log('Hub is now running and ready to accept messages');
        this.log('Press Ctrl+C to exit and stop the hub');
        
        // Don't auto-exit - let user control the process
        resolve({
            processId: this.processId,
            registry: CONFIG.registry.processId,
            success: true
        });
    }

    saveDeploymentLog() {
        try {
            const logContent = this.deploymentLog.join('\n') + '\n';
            fs.writeFileSync(CONFIG.files.deployLog, logContent);
            this.log(`Deployment log saved to: ${CONFIG.files.deployLog}`);
        } catch (error) {
            this.log(`Failed to save deployment log: ${error.message}`);
        }
    }

    async deploy() {
        try {
            await this.checkDependencies();
            const result = await this.deployHub();
            return result;
        } catch (error) {
            this.log(`Deployment failed: ${error.message}`);
            throw error;
        }
    }
}

// CLI Usage
if (require.main === module) {
    const deployer = new OpenHubDeployer();
    
    deployer.deploy()
        .then((result) => {
            console.log('\n=== Deployment Summary ===');
            console.log(`Process ID: ${result.processId}`);
            console.log(`Registry: ${result.registry}`);
            console.log('Status: Success');
            console.log('\nYour Velocity Protocol Open Hub is now live!');
            console.log('\nNext steps:');
            console.log('1. Share your hub process ID with users');
            console.log('2. Monitor the deployment log for any issues');
            console.log('3. Test messaging functionality');
            console.log('\nPress Ctrl+C to stop the hub process');
        })
        .catch((error) => {
            console.error('\n=== Deployment Failed ===');
            console.error(`Error: ${error.message}`);
            console.error('\nPlease check the deployment log for details');
            process.exit(1);
        });
}

module.exports = OpenHubDeployer;