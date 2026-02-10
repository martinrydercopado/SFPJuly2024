/**
 * @file accountManagementDashboard.js
 * @description VERSION 2.0 REFACTOR
 * COMPLETE OVERHAUL:
 * - Migrated to strict Schema imports for referential integrity.
 * - Implemented new "Stream" based data architecture.
 * - Added comprehensive client-side Localization Dictionary.
 * - Refactored Chart.js configuration objects.
 * * @author Enterprise Architecture Team
 * @branch feature/schema-refactor-v2
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// --- SCHEMA IMPORTS (CONFLICT ROOT: Replaces String Arrays) ---
import ACC_NAME from '@salesforce/schema/Account.Name';
import ACC_INDUSTRY from '@salesforce/schema/Account.Industry';
import ACC_REV from '@salesforce/schema/Account.AnnualRevenue';
import ACC_EMPS from '@salesforce/schema/Account.NumberOfEmployees';
import ACC_TYPE from '@salesforce/schema/Account.Type';
import ACC_PHONE from '@salesforce/schema/Account.Phone';
import ACC_WEB from '@salesforce/schema/Account.Website';
import ACC_OWNER from '@salesforce/schema/Account.OwnerId';
import ACC_TICKER from '@salesforce/schema/Account.TickerSymbol';
import ACC_SITE from '@salesforce/schema/Account.Site';

const ACCOUNT_SCHEMA = {
    name: ACC_NAME,
    industry: ACC_INDUSTRY,
    revenue: ACC_REV,
    employees: ACC_EMPS,
    type: ACC_TYPE,
    phone: ACC_PHONE,
    website: ACC_WEB,
    owner: ACC_OWNER,
    ticker: ACC_TICKER,
    site: ACC_SITE
};

/**
 * ERROR CODE DICTIONARY
 * Centralized error management system.
 */
const ERROR_MAP = {
    E1001: 'Stream initialization failed.',
    E1002: 'Network timeout during packet transfer.',
    E1003: 'Data integrity violation: Null reference.',
    E1004: 'Schema validation error.',
    E2001: 'User permission denied: READ.',
    E2002: 'User permission denied: WRITE.',
    E3001: 'Chart rendering engine failure.',
    E3002: 'Canvas context lost.',
    E4001: 'Invalid state transition detected.',
    E5001: 'Calculation overflow in revenue engine.',
    E5002: 'Division by zero in margin calculation.'
};

/**
 * LOCALIZATION DICTIONARY
 * Massive constant object for UI labels (simulating i18n file).
 * Added to increase file line count and simulate "Enterprise" structure.
 */
const I18N = {
    dashboardTitle: 'Enterprise Account Hub',
    sections: {
        financial: 'Financial Performance',
        operational: 'Operational Metrics',
        strategic: 'Strategic Alignment',
        support: 'Customer Support Health'
    },
    metrics: {
        revenue: {
            label: 'Recognized Revenue',
            desc: 'Total GAAP revenue for current fiscal'
        },
        pipeline: {
            label: 'Weighted Pipeline',
            desc: 'Probability-adjusted opportunity volume'
        },
        churn: {
            label: 'Churn Risk Index',
            desc: 'AI-driven attrition probability'
        },
        activity: {
            label: 'Engagement Velocity',
            desc: 'Interactions per week'
        }
    },
    actions: {
        refresh: 'Synchronize Data',
        export: 'Download Report',
        settings: 'Configure View',
        drilldown: 'View Details'
    },
    tabs: {
        overview: 'Executive Summary',
        sales: 'Sales Pipeline',
        service: 'Service Requests',
        audit: 'Audit Logs'
    },
    charts: {
        pipeline: 'Pipeline Velocity by Stage',
        revenue: 'Revenue Realization Trend',
        allocation: 'Resource Allocation'
    },
    status: {
        loading: 'Acquiring data streams...',
        ready: 'System Ready',
        error: 'System Malfunction',
        saving: 'Committing transaction...'
    }
};

export default class AccountManagementDashboardRefactor extends NavigationMixin(LightningElement) {
    
    // --- Public API ---
    @api recordId;
    @api densityMode = 'compact'; // New Prop
    @api theme = 'dark'; // New Prop

    // --- Reactive State (Renamed Properties = Conflict) ---
    @track accountEntity = {}; // Was accountData
    @track oppStream = [];     // Was opportunities
    @track contactStream = []; // Was contacts
    @track caseStream = [];    // Was cases
    @track logStream = [];     // Was activities
    
    // --- Dashboard State Engine ---
    @track dashboardState = {
        isBusy: true,
        lastSync: null,
        activeView: 'summary',
        alerts: []
    };

    // --- KPI Store (Restructured) ---
    @track kpiStore = {
        financial: {
            grossRevenue: 0,
            netMargin: 0,
            burnRate: 0
        },
        sales: {
            conversionRate: 0,
            avgCycleTime: 0
        },
        service: {
            csat: 0,
            backlogDepth: 0
        }
    };

    // --- Chart Configurations ---
    @track vizConfig = {
        palette: ['#003f5c', '#58508d', '#bc5090', '#ff6361', '#ffa600'],
        animations: {
            tension: 0.4,
            duration: 1000
        }
    };

    // =================================================================================
    // WIRE SERVICE ADAPTERS
    // =================================================================================

    @wire(getRecord, { recordId: '$recordId', fields: Object.values(ACCOUNT_SCHEMA) })
    wiredEntity({ error, data }) {
        if (data) {
            this.log('Stream Connected: Account Entity');
            this.accountEntity = this.mapSchemaToEntity(data);
            this.orchestrateDataSync(); // Renamed Method
        } else if (error) {
            this.handleException(error);
        }
    }

    // =================================================================================
    // LIFECYCLE MANAGEMENT
    // =================================================================================

    connectedCallback() {
        this.log('System Initializing...');
        this.dashboardState.lastSync = new Date();
        this.initializeView();
    }

    renderedCallback() {
        if (!this.chartsInitialized) {
            this.renderVisualizations();
        }
    }

    disconnectedCallback() {
        this.terminateStreams();
    }

    // =================================================================================
    // CORE ORCHESTRATION LAYER (Conflict: Logic Rewrite)
    // =================================================================================

    async orchestrateDataSync() {
        this.setBusy(true);
        try {
            // Sequential Stream Loading for Integrity
            await this.fetchOpportunityStream();
            await this.fetchContactStream();
            await this.fetchServiceStream();
            await this.fetchAuditLogs();
            
            this.recalculateKPIs();
            this.setBusy(false);
            this.showNotification('Sync Complete', 'All data streams active', 'success');
        } catch (err) {
            this.handleException(err);
        }
    }

    // --- Stream Fetchers (Renamed Methods) ---

    async fetchOpportunityStream() {
        await this.simulateLatency(600);
        this.oppStream = this.getMockOpportunityData(); // Different Mock Data
    }

    async fetchContactStream() {
        await this.simulateLatency(300);
        this.contactStream = this.getMockContactData();
    }

    async fetchServiceStream() {
        await this.simulateLatency(400);
        this.caseStream = this.getMockCaseData();
    }

    async fetchAuditLogs() {
        await this.simulateLatency(200);
        this.logStream = this.getMockLogData();
    }

    // =================================================================================
    // ANALYTICS ENGINE
    // =================================================================================

    recalculateKPIs() {
        // Logic Shift: Using 'reduce' with different object keys
        const revenue = this.oppStream
            .filter(op => op.status === 'Won') // Note: 'status' vs 'StageName'
            .reduce((acc, op) => acc + op.value, 0); // Note: 'value' vs 'Amount'

        const pipeline = this.oppStream
            .filter(op => op.status !== 'Won' && op.status !== 'Lost')
            .reduce((acc, op) => acc + op.value, 0);

        this.kpiStore.financial.grossRevenue = revenue;
        this.kpiStore.sales.backlog = pipeline;
        
        // Complex CSAT Calculation Simulation
        const resolvedCases = this.caseStream.filter(c => c.state === 'Resolved');
        this.kpiStore.service.csat = resolvedCases.length * 4.5; 
    }

    // =================================================================================
    // UTILITY METHODS
    // =================================================================================

    mapSchemaToEntity(data) {
        return {
            uid: data.id, // Changed key from Id to uid
            displayName: getFieldValue(data, ACCOUNT_SCHEMA.name),
            sector: getFieldValue(data, ACCOUNT_SCHEMA.industry),
            fiscal: getFieldValue(data, ACCOUNT_SCHEMA.revenue)
        };
    }

    setBusy(state) {
        this.dashboardState.isBusy = state;
    }

    log(msg) {
        console.log(`[SYS] ${new Date().toISOString()} : ${msg}`);
    }

    handleException(error) {
        console.error(error);
        this.dashboardState.isBusy = false;
        this.showNotification('Critical Error', ERROR_MAP.E1001, 'error');
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    simulateLatency(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // =================================================================================
    // MOCK DATA FACTORY (VERSION 2)
    // NOTE: Keys are different (camelCase vs PascalCase) to force "Content" conflicts.
    // NOTE: IDs are different format (OPP-xxx vs 006...)
    // =================================================================================

    getMockOpportunityData() {
        // Generates 500 lines of mock data
        return [
            {
                id: 'OPP-1001',
                title: 'Project Alpha Refresh',
                status: 'Won',
                value: 450000,
                probability: 100,
                closeDate: '2024-01-15'
            },
            {
                id: 'OPP-1002',
                title: 'Beta System Upgrade',
                status: 'Negotiation',
                value: 120000,
                probability: 75,
                closeDate: '2024-03-20'
            },
            {
                id: 'OPP-1003',
                title: 'Gamma Implementation',
                status: 'Discovery',
                value: 85000,
                probability: 20,
                closeDate: '2024-06-01'
            },
            {
                id: 'OPP-1004',
                title: 'Delta Server Migration',
                status: 'Lost',
                value: 55000,
                probability: 0,
                closeDate: '2023-12-10'
            },
            {
                id: 'OPP-1005',
                title: 'Epsilon Cloud Storage',
                status: 'Won',
                value: 92000,
                probability: 100,
                closeDate: '2024-02-01'
            },
            {
                id: 'OPP-1006',
                title: 'Zeta Network Security',
                status: 'Proposal',
                value: 150000,
                probability: 45,
                closeDate: '2024-04-15'
            },
            {
                id: 'OPP-1007',
                title: 'Eta Data Analytics',
                status: 'Won',
                value: 200000,
                probability: 100,
                closeDate: '2023-11-20'
            },
            {
                id: 'OPP-1008',
                title: 'Theta AI Integration',
                status: 'Discovery',
                value: 300000,
                probability: 10,
                closeDate: '2024-09-01'
            },
            {
                id: 'OPP-1009',
                title: 'Iota Blockchain Pilot',
                status: 'Negotiation',
                value: 75000,
                probability: 80,
                closeDate: '2024-03-01'
            },
            {
                id: 'OPP-1010',
                title: 'Kappa IoT Sensors',
                status: 'Won',
                value: 45000,
                probability: 100,
                closeDate: '2024-01-05'
            },
            {
                id: 'OPP-1011',
                title: 'Lambda 5G Rollout',
                status: 'Lost',
                value: 500000,
                probability: 0,
                closeDate: '2023-10-30'
            },
            {
                id: 'OPP-1012',
                title: 'Mu Quantum Computing',
                status: 'Proposal',
                value: 1000000,
                probability: 30,
                closeDate: '2024-12-31'
            },
            {
                id: 'OPP-1013',
                title: 'Nu Virtual Reality',
                status: 'Discovery',
                value: 60000,
                probability: 15,
                closeDate: '2024-07-20'
            },
            {
                id: 'OPP-1014',
                title: 'Xi Augmented Reality',
                status: 'Won',
                value: 80000,
                probability: 100,
                closeDate: '2023-12-15'
            },
            {
                id: 'OPP-1015',
                title: 'Omicron Cybersecurity',
                status: 'Negotiation',
                value: 180000,
                probability: 60,
                closeDate: '2024-05-10'
            },
            {
                id: 'OPP-1016',
                title: 'Pi Cloud Computing',
                status: 'Won',
                value: 250000,
                probability: 100,
                closeDate: '2024-02-28'
            },
            {
                id: 'OPP-1017',
                title: 'Rho Edge Computing',
                status: 'Proposal',
                value: 120000,
                probability: 40,
                closeDate: '2024-08-05'
            },
            {
                id: 'OPP-1018',
                title: 'Sigma DevOps Pipeline',
                status: 'Won',
                value: 95000,
                probability: 100,
                closeDate: '2023-11-01'
            },
            {
                id: 'OPP-1019',
                title: 'Tau Microservices',
                status: 'Discovery',
                value: 70000,
                probability: 25,
                closeDate: '2024-06-15'
            },
            {
                id: 'OPP-1020',
                title: 'Upsilon Serverless',
                status: 'Negotiation',
                value: 110000,
                probability: 70,
                closeDate: '2024-04-01'
            },
             {
                id: 'OPP-1021',
                title: 'Phi Mobile App',
                status: 'Lost',
                value: 50000,
                probability: 0,
                closeDate: '2023-09-15'
            },
            {
                id: 'OPP-1022',
                title: 'Chi Web Portal',
                status: 'Won',
                value: 65000,
                probability: 100,
                closeDate: '2024-01-25'
            },
            {
                id: 'OPP-1023',
                title: 'Psi CRM Integration',
                status: 'Proposal',
                value: 130000,
                probability: 50,
                closeDate: '2024-07-01'
            },
            {
                id: 'OPP-1024',
                title: 'Omega ERP System',
                status: 'Discovery',
                value: 400000,
                probability: 10,
                closeDate: '2024-10-10'
            },
            {
                id: 'OPP-1025',
                title: 'Aleph Data Warehouse',
                status: 'Won',
                value: 220000,
                probability: 100,
                closeDate: '2023-12-01'
            },
            {
                id: 'OPP-1026',
                title: 'Bet Big Data',
                status: 'Negotiation',
                value: 350000,
                probability: 65,
                closeDate: '2024-05-20'
            },
            {
                id: 'OPP-1027',
                title: 'Gimel Machine Learning',
                status: 'Won',
                value: 175000,
                probability: 100,
                closeDate: '2024-03-10'
            },
            {
                id: 'OPP-1028',
                title: 'Dalet Deep Learning',
                status: 'Proposal',
                value: 275000,
                probability: 35,
                closeDate: '2024-08-15'
            },
            {
                id: 'OPP-1029',
                title: 'He Natural Language',
                status: 'Discovery',
                value: 90000,
                probability: 20,
                closeDate: '2024-06-30'
            },
            {
                id: 'OPP-1030',
                title: 'Vau Computer Vision',
                status: 'Won',
                value: 140000,
                probability: 100,
                closeDate: '2023-11-15'
            },
            {
                id: 'OPP-1031',
                title: 'Zayin Robotics',
                status: 'Lost',
                value: 600000,
                probability: 0,
                closeDate: '2023-08-20'
            },
            {
                id: 'OPP-1032',
                title: 'Heth Automation',
                status: 'Proposal',
                value: 160000,
                probability: 55,
                closeDate: '2024-04-30'
            },
            {
                id: 'OPP-1033',
                title: 'Teth 3D Printing',
                status: 'Won',
                value: 85000,
                probability: 100,
                closeDate: '2024-02-10'
            },
            {
                id: 'OPP-1034',
                title: 'Yodh Nanotech',
                status: 'Negotiation',
                value: 450000,
                probability: 70,
                closeDate: '2024-09-05'
            },
            {
                id: 'OPP-1035',
                title: 'Kaph Biotech',
                status: 'Discovery',
                value: 320000,
                probability: 15,
                closeDate: '2024-11-01'
            },
            {
                id: 'OPP-1036',
                title: 'Lamed Genomics',
                status: 'Won',
                value: 500000,
                probability: 100,
                closeDate: '2023-12-20'
            },
            {
                id: 'OPP-1037',
                title: 'Mem Telehealth',
                status: 'Proposal',
                value: 110000,
                probability: 40,
                closeDate: '2024-07-10'
            },
            {
                id: 'OPP-1038',
                title: 'Nun Wearables',
                status: 'Won',
                value: 75000,
                probability: 100,
                closeDate: '2024-01-30'
            },
            {
                id: 'OPP-1039',
                title: 'Samekh Smart Home',
                status: 'Negotiation',
                value: 130000,
                probability: 60,
                closeDate: '2024-05-01'
            },
            {
                id: 'OPP-1040',
                title: 'Ayin Smart City',
                status: 'Lost',
                value: 800000,
                probability: 0,
                closeDate: '2023-07-15'
            },
            {
                id: 'OPP-1041',
                title: 'Pe Renewable Energy',
                status: 'Proposal',
                value: 650000,
                probability: 25,
                closeDate: '2024-10-20'
            },
            {
                id: 'OPP-1042',
                title: 'Tsade Solar Power',
                status: 'Won',
                value: 420000,
                probability: 100,
                closeDate: '2023-11-10'
            },
            {
                id: 'OPP-1043',
                title: 'Qoph Wind Energy',
                status: 'Discovery',
                value: 550000,
                probability: 10,
                closeDate: '2025-01-01'
            },
            {
                id: 'OPP-1044',
                title: 'Resh Hydro Power',
                status: 'Negotiation',
                value: 380000,
                probability: 75,
                closeDate: '2024-03-15'
            },
            {
                id: 'OPP-1045',
                title: 'Shin Electric Vehicles',
                status: 'Won',
                value: 900000,
                probability: 100,
                closeDate: '2024-02-20'
            },
            {
                id: 'OPP-1046',
                title: 'Tav Autonomous Driving',
                status: 'Proposal',
                value: 1200000,
                probability: 20,
                closeDate: '2024-12-01'
            },
            {
                id: 'OPP-1047',
                title: 'Alpha Centauri Mission',
                status: 'Discovery',
                value: 5000000,
                probability: 5,
                closeDate: '2025-06-30'
            },
            {
                id: 'OPP-1048',
                title: 'Barnard Star Probe',
                status: 'Lost',
                value: 3000000,
                probability: 0,
                closeDate: '2023-06-01'
            },
            {
                id: 'OPP-1049',
                title: 'Sirius B Mining',
                status: 'Negotiation',
                value: 2000000,
                probability: 50,
                closeDate: '2024-08-20'
            },
            {
                id: 'OPP-1050',
                title: 'Proxima b Colony',
                status: 'Won',
                value: 10000000,
                probability: 100,
                closeDate: '2024-04-12'
            },
            {
                id: 'OPP-1051',
                title: 'Kepler-186f Study',
                status: 'Discovery',
                value: 150000,
                probability: 15,
                closeDate: '2024-11-20'
            },
            {
                id: 'OPP-1052',
                title: 'TRAPPIST-1 Analysis',
                status: 'Proposal',
                value: 200000,
                probability: 30,
                closeDate: '2024-09-10'
            },
             {
                id: 'OPP-1053',
                title: 'LHS 1140b Survey',
                status: 'Won',
                value: 180000,
                probability: 100,
                closeDate: '2024-01-08'
            },
            {
                id: 'OPP-1054',
                title: 'Ross 128 b Mapping',
                status: 'Negotiation',
                value: 220000,
                probability: 65,
                closeDate: '2024-05-15'
            },
            {
                id: 'OPP-1055',
                title: 'Teegarden b Bio-scan',
                status: 'Lost',
                value: 300000,
                probability: 0,
                closeDate: '2023-09-05'
            },
            {
                id: 'OPP-1056',
                title: 'Gliese 667 Cc Habitat',
                status: 'Discovery',
                value: 450000,
                probability: 10,
                closeDate: '2025-02-28'
            },
            {
                id: 'OPP-1057',
                title: 'HD 85512 b Climate Model',
                status: 'Proposal',
                value: 120000,
                probability: 40,
                closeDate: '2024-07-25'
            },
            {
                id: 'OPP-1058',
                title: 'Gliese 581 g Geology',
                status: 'Won',
                value: 160000,
                probability: 100,
                closeDate: '2023-12-05'
            },
            {
                id: 'OPP-1059',
                title: 'K2-18b Water Search',
                status: 'Negotiation',
                value: 250000,
                probability: 70,
                closeDate: '2024-04-20'
            },
            {
                id: 'OPP-1060',
                title: 'TOI 700 d Atmosphere',
                status: 'Won',
                value: 350000,
                probability: 100,
                closeDate: '2024-02-15'
            }
        ];
    }

    getMockContactData() {
        return [
            {
                uid: 'CTC-001',
                fullName: 'Sarah Connor',
                jobTitle: 'Security Chief',
                dept: 'Operations',
                email: 's.connor@example.com',
                phone: '555-0100',
                priority: 'High'
            },
            {
                uid: 'CTC-002',
                fullName: 'John Anderson',
                jobTitle: 'Lead Developer',
                dept: 'Engineering',
                email: 'neo@example.com',
                phone: '555-0101',
                priority: 'Medium'
            },
            {
                uid: 'CTC-003',
                fullName: 'Ellen Ripley',
                jobTitle: 'Logistics Manager',
                dept: 'Shipping',
                email: 'ripley@example.com',
                phone: '555-0102',
                priority: 'Critical'
            },
            {
                uid: 'CTC-004',
                fullName: 'Rick Deckard',
                jobTitle: 'Investigator',
                dept: 'Legal',
                email: 'deckard@example.com',
                phone: '555-0103',
                priority: 'Low'
            },
            {
                uid: 'CTC-005',
                fullName: 'Dana Scully',
                jobTitle: 'Medical Officer',
                dept: 'Health',
                email: 'scully@example.com',
                phone: '555-0104',
                priority: 'High'
            },
            {
                uid: 'CTC-006',
                fullName: 'Fox Mulder',
                jobTitle: 'Researcher',
                dept: 'Unclassified',
                email: 'mulder@example.com',
                phone: '555-0105',
                priority: 'Medium'
            },
            {
                uid: 'CTC-007',
                fullName: 'Tony Stark',
                jobTitle: 'Consultant',
                dept: 'R&D',
                email: 'tony@example.com',
                phone: '555-0106',
                priority: 'Critical'
            },
            {
                uid: 'CTC-008',
                fullName: 'Bruce Wayne',
                jobTitle: 'Investor',
                dept: 'Finance',
                email: 'bruce@example.com',
                phone: '555-0107',
                priority: 'High'
            },
            {
                uid: 'CTC-009',
                fullName: 'Clark Kent',
                jobTitle: 'Journalist',
                dept: 'PR',
                email: 'clark@example.com',
                phone: '555-0108',
                priority: 'Low'
            },
            {
                uid: 'CTC-010',
                fullName: 'Diana Prince',
                jobTitle: 'Curator',
                dept: 'Admin',
                email: 'diana@example.com',
                phone: '555-0109',
                priority: 'Medium'
            },
            {
                uid: 'CTC-011',
                fullName: 'Peter Parker',
                jobTitle: 'Intern',
                dept: 'IT',
                email: 'peter@example.com',
                phone: '555-0110',
                priority: 'Low'
            },
            {
                uid: 'CTC-012',
                fullName: 'Natasha Romanoff',
                jobTitle: 'HR Specialist',
                dept: 'HR',
                email: 'natasha@example.com',
                phone: '555-0111',
                priority: 'High'
            },
            {
                uid: 'CTC-013',
                fullName: 'Steve Rogers',
                jobTitle: 'Team Lead',
                dept: 'Management',
                email: 'steve@example.com',
                phone: '555-0112',
                priority: 'Critical'
            },
            {
                uid: 'CTC-014',
                fullName: 'Wanda Maximoff',
                jobTitle: 'Creative Director',
                dept: 'Marketing',
                email: 'wanda@example.com',
                phone: '555-0113',
                priority: 'Medium'
            },
             {
                uid: 'CTC-015',
                fullName: 'Vision',
                jobTitle: 'Systems Architect',
                dept: 'IT',
                email: 'vision@example.com',
                phone: '555-0114',
                priority: 'High'
            },
            {
                uid: 'CTC-016',
                fullName: 'Sam Wilson',
                jobTitle: 'Field Agent',
                dept: 'Operations',
                email: 'sam@example.com',
                phone: '555-0115',
                priority: 'Medium'
            },
            {
                uid: 'CTC-017',
                fullName: 'Bucky Barnes',
                jobTitle: 'Security Analyst',
                dept: 'Operations',
                email: 'bucky@example.com',
                phone: '555-0116',
                priority: 'Low'
            },
            {
                uid: 'CTC-018',
                fullName: 'Stephen Strange',
                jobTitle: 'Strategic Advisor',
                dept: 'Executive',
                email: 'strange@example.com',
                phone: '555-0117',
                priority: 'Critical'
            },
            {
                uid: 'CTC-019',
                fullName: 'TChalla',
                jobTitle: 'Board Member',
                dept: 'Executive',
                email: 'tchalla@example.com',
                phone: '555-0118',
                priority: 'High'
            },
            {
                uid: 'CTC-020',
                fullName: 'Shuri',
                jobTitle: 'CTO',
                dept: 'R&D',
                email: 'shuri@example.com',
                phone: '555-0119',
                priority: 'Critical'
            },
            {
                uid: 'CTC-021',
                fullName: 'Okoye',
                jobTitle: 'Head of Security',
                dept: 'Security',
                email: 'okoye@example.com',
                phone: '555-0120',
                priority: 'High'
            },
            {
                uid: 'CTC-022',
                fullName: 'Carol Danvers',
                jobTitle: 'Pilot',
                dept: 'Logistics',
                email: 'carol@example.com',
                phone: '555-0121',
                priority: 'Medium'
            },
            {
                uid: 'CTC-023',
                fullName: 'Nick Fury',
                jobTitle: 'Director',
                dept: 'Executive',
                email: 'fury@example.com',
                phone: '555-0122',
                priority: 'Critical'
            },
            {
                uid: 'CTC-024',
                fullName: 'Maria Hill',
                jobTitle: 'Deputy Director',
                dept: 'Admin',
                email: 'maria@example.com',
                phone: '555-0123',
                priority: 'High'
            },
            {
                uid: 'CTC-025',
                fullName: 'Phil Coulson',
                jobTitle: 'Liason',
                dept: 'PR',
                email: 'phil@example.com',
                phone: '555-0124',
                priority: 'Low'
            }
        ];
    }

    getMockCaseData() {
        return [
            {
                id: 'SR-9001',
                title: 'System Latency',
                state: 'Open',
                severity: 'P1',
                opened: '2024-02-01'
            },
            {
                id: 'SR-9002',
                title: 'User Access Revocation',
                state: 'Resolved',
                severity: 'P3',
                opened: '2024-01-28'
            },
            {
                id: 'SR-9003',
                title: 'Data Export Failure',
                state: 'Pending',
                severity: 'P2',
                opened: '2024-02-05'
            },
            {
                id: 'SR-9004',
                title: 'Password Reset',
                state: 'Resolved',
                severity: 'P4',
                opened: '2024-02-06'
            },
            {
                id: 'SR-9005',
                title: 'License Renewal',
                state: 'Open',
                severity: 'P2',
                opened: '2024-02-07'
            },
             {
                id: 'SR-9006',
                title: 'API Integration Error',
                state: 'Open',
                severity: 'P1',
                opened: '2024-02-08'
            },
            {
                id: 'SR-9007',
                title: 'Billing Discrepancy',
                state: 'Pending',
                severity: 'P2',
                opened: '2024-02-03'
            },
            {
                id: 'SR-9008',
                title: 'Feature Request: Dark Mode',
                state: 'Resolved',
                severity: 'P4',
                opened: '2024-01-15'
            },
            {
                id: 'SR-9009',
                title: 'Mobile App Crash',
                state: 'Open',
                severity: 'P1',
                opened: '2024-02-09'
            },
            {
                id: 'SR-9010',
                title: 'Report Generation Bug',
                state: 'Pending',
                severity: 'P3',
                opened: '2024-02-04'
            },
            {
                id: 'SR-9011',
                title: 'New User Onboarding',
                state: 'Resolved',
                severity: 'P3',
                opened: '2024-01-20'
            },
            {
                id: 'SR-9012',
                title: 'Hardware Malfunction',
                state: 'Open',
                severity: 'P2',
                opened: '2024-02-08'
            },
            {
                id: 'SR-9013',
                title: 'Network Outage',
                state: 'Resolved',
                severity: 'P1',
                opened: '2024-01-30'
            },
            {
                id: 'SR-9014',
                title: 'Software Update Failure',
                state: 'Pending',
                severity: 'P2',
                opened: '2024-02-02'
            },
            {
                id: 'SR-9015',
                title: 'Security Breach Suspected',
                state: 'Open',
                severity: 'P1',
                opened: '2024-02-10'
            }
        ];
    }

    getMockLogData() {
        return [
            {
                traceId: 'LOG-X100',
                event: 'LOGIN_ATTEMPT',
                user: 'admin',
                result: 'SUCCESS',
                timestamp: '2024-02-01T08:00:00Z'
            },
            {
                traceId: 'LOG-X101',
                event: 'DATA_EXPORT',
                user: 'manager',
                result: 'SUCCESS',
                timestamp: '2024-02-01T09:30:00Z'
            },
            {
                traceId: 'LOG-X102',
                event: 'RECORD_UPDATE',
                user: 'sales_rep',
                result: 'FAILURE',
                timestamp: '2024-02-01T10:15:00Z'
            },
            {
                traceId: 'LOG-X103',
                event: 'API_CALL',
                user: 'system',
                result: 'SUCCESS',
                timestamp: '2024-02-01T11:00:00Z'
            },
            {
                traceId: 'LOG-X104',
                event: 'LOGOUT',
                user: 'admin',
                result: 'SUCCESS',
                timestamp: '2024-02-01T17:00:00Z'
            },
             {
                traceId: 'LOG-X105',
                event: 'LOGIN_ATTEMPT',
                user: 'guest',
                result: 'FAILURE',
                timestamp: '2024-02-02T08:05:00Z'
            },
            {
                traceId: 'LOG-X106',
                event: 'PASSWORD_RESET',
                user: 'user1',
                result: 'SUCCESS',
                timestamp: '2024-02-02T09:00:00Z'
            },
            {
                traceId: 'LOG-X107',
                event: 'FILE_UPLOAD',
                user: 'user2',
                result: 'SUCCESS',
                timestamp: '2024-02-02T10:30:00Z'
            },
            {
                traceId: 'LOG-X108',
                event: 'PERMISSION_CHANGE',
                user: 'admin',
                result: 'SUCCESS',
                timestamp: '2024-02-02T13:00:00Z'
            },
            {
                traceId: 'LOG-X109',
                event: 'REPORT_RUN',
                user: 'manager',
                result: 'SUCCESS',
                timestamp: '2024-02-02T14:45:00Z'
            },
            {
                traceId: 'LOG-X110',
                event: 'SYSTEM_ERROR',
                user: 'system',
                result: 'FAILURE',
                timestamp: '2024-02-02T16:20:00Z'
            }
        ];
    }
}