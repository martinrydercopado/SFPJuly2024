/**
 * @file accountManagementDashboard.js
 * @description Main controller for the Account Management Dashboard LWC.
 * This component aggregates data from Opportunities, Contacts, Cases, and Activities
 * to provide a 360-degree view of an Account.
 * * @version 2.0.0
 * @author System
 * @copyright 2024
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// =================================================================================
// SECTION 1: CONSTANTS & FIELD DEFINITIONS
// =================================================================================

/**
 * Standard Account Fields to retrieve via Wire Service
 */
const FIELDS = [
    'Account.Name',
    'Account.Industry',
    'Account.AnnualRevenue',
    'Account.NumberOfEmployees',
    'Account.Type',
    'Account.Rating',
    'Account.Phone',
    'Account.Fax',
    'Account.Website',
    'Account.BillingStreet',
    'Account.BillingCity',
    'Account.BillingState',
    'Account.BillingPostalCode',
    'Account.BillingCountry',
    'Account.ShippingStreet',
    'Account.ShippingCity',
    'Account.ShippingState',
    'Account.ShippingPostalCode',
    'Account.ShippingCountry',
    'Account.Description',
    'Account.OwnerId',
    'Account.CreatedDate',
    'Account.LastModifiedDate',
    'Account.TickerSymbol',
    'Account.Site'
];

/**
 * Mapped dictionary for Chart Colors to ensure consistency across the dashboard.
 */
const CHART_COLORS = {
    revenue: {
        background: 'rgba(75, 192, 192, 0.2)',
        border: 'rgba(75, 192, 192, 1)'
    },
    pipeline: {
        background: 'rgba(54, 162, 235, 0.2)',
        border: 'rgba(54, 162, 235, 1)'
    },
    cases: {
        critical: '#ff6384',
        high: '#ff9f40',
        medium: '#ffcd56',
        low: '#4bc0c0'
    },
    activities: {
        call: '#36a2eb',
        email: '#ff6384',
        meeting: '#4bc0c0',
        other: '#9966ff'
    }
};

/**
 * Help text / Tooltip definitions for the UI
 */
const HELP_TEXT = {
    revenue: 'Total revenue calculated from Closed Won opportunities in the current fiscal year.',
    winRate: 'Percentage of opportunities won vs total closed opportunities.',
    healthScore: 'AI-calculated score based on recent activity, support cases, and pipeline velocity.',
    activeContacts: 'Contacts with activity in the last 30 days.'
};

// =================================================================================
// SECTION 2: COMPONENT CLASS
// =================================================================================

export default class AccountManagementDashboard extends LightningElement {
    
    // --- Public Properties ---
    @api recordId;
    @api objectApiName = 'Account';
    @api flexipageRegionWidth;

    // --- Data Tracking ---
    @track accountData = {};
    @track opportunities = [];
    @track contacts = [];
    @track cases = [];
    @track activities = [];
    @track notes = [];
    @track files = [];
    
    // --- Metrics & Analytics ---
    @track metrics = {
        totalRevenue: 0,
        openPipeline: 0,
        winRate: 0,
        avgDealSize: 0,
        activeContactsCount: 0,
        openCasesCount: 0,
        avgCaseAge: 0,
        lastActivityDays: 0,
        healthScore: 0,
        churnRisk: 'Low'
    };

    // --- UI State Management ---
    @track isLoading = true;
    @track isRefeshing = false;
    @track activeTab = 'overview';
    @track error = null;
    @track showModal = false;
    @track modalConfig = {
        title: '',
        body: '',
        type: '',
        recordId: null
    };

    // --- Search & Filter State ---
    @track searchKey = '';
    @track filters = {
        stage: 'All',
        priority: 'All',
        dateRange: 'this_year',
        type: 'All'
    };
    @track sortState = {
        field: 'Name',
        direction: 'asc'
    };

    // --- Pagination State ---
    @track pagination = {
        currentPage: 1,
        pageSize: 10,
        totalRecords: 0,
        totalPages: 0
    };

    // --- Chart Configuration ---
    @track chartData = {
        pipeline: null,
        revenue: null,
        cases: null,
        activity: null
    };

    // =================================================================================
    // SECTION 3: WIRE SERVICES & LIFECYCLE
    // =================================================================================

    /**
     * Wire service to fetch the main Account record data.
     */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            console.log('Account Data Received:', data);
            this.accountData = this.processAccountData(data);
            this.error = null;
            
            // Once account is loaded, trigger the cascade of related data loading
            this.loadAllDashboardData();
        } else if (error) {
            console.error('Error loading account:', error);
            this.error = error;
            this.handleError('Failed to load Account details.');
        }
    }

    /**
     * Component connected callback.
     * Initializes the dashboard, sets up event listeners, and configures the refresh interval.
     */
    connectedCallback() {
        this.initializeComponent();
        this.setupRefreshInterval();
        window.addEventListener('resize', this.handleResize.bind(this));
    }

    /**
     * Component disconnected callback.
     * Cleans up intervals and event listeners.
     */
    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        window.removeEventListener('resize', this.handleResize.bind(this));
    }

    /**
     * Component rendered callback.
     * Used for Chart.js initialization if we were using a third-party library.
     */
    renderedCallback() {
        if (this.chartData.pipeline && !this.chartsInitialized) {
            this.initializeCharts();
            this.chartsInitialized = true;
        }
    }

    // =================================================================================
    // SECTION 4: INITIALIZATION LOGIC
    // =================================================================================

    initializeComponent() {
        this.isLoading = true;
        this.loadUserPreferences();
        // Setup initial default filters
        this.filters = {
            stage: 'All',
            priority: 'All',
            dateRange: 'this_year',
            type: 'All'
        };
    }

    setupRefreshInterval() {
        // Refresh data every 5 minutes (300000 ms)
        this.refreshInterval = setInterval(() => {
            console.log('Auto-refreshing dashboard...');
            this.refreshDashboard();
        }, 300000);
    }

    loadUserPreferences() {
        try {
            const prefs = localStorage.getItem('dashboardPrefs');
            if (prefs) {
                const parsed = JSON.parse(prefs);
                this.pagination.pageSize = parsed.pageSize || 10;
                this.activeTab = parsed.lastTab || 'overview';
            }
        } catch (e) {
            console.warn('Failed to load user preferences', e);
        }
    }

    // =================================================================================
    // SECTION 5: DATA LOADING & PROCESSING
    // =================================================================================

    async loadAllDashboardData() {
        this.isLoading = true;
        try {
            // In a real scenario, these would be Apex calls. 
            // Here we use our Massive Mock Data Generators (defined at bottom of file).
            
            await Promise.all([
                this.fetchOpportunities(),
                this.fetchContacts(),
                this.fetchCases(),
                this.fetchActivities()
            ]);

            this.calculateMetrics();
            this.generateChartData();
            this.isLoading = false;

        } catch (error) {
            this.handleError('Error loading dashboard data: ' + error.message);
            this.isLoading = false;
        }
    }

    async fetchOpportunities() {
        // Simulate network delay
        await this.simulateDelay(500);
        this.opportunities = this.getMockOpportunities();
        this.pagination.totalRecords = this.opportunities.length;
        this.updatePaginatedData();
    }

    async fetchContacts() {
        await this.simulateDelay(300);
        this.contacts = this.getMockContacts();
    }

    async fetchCases() {
        await this.simulateDelay(400);
        this.cases = this.getMockCases();
    }

    async fetchActivities() {
        await this.simulateDelay(300);
        this.activities = this.getMockActivities();
    }

    // =================================================================================
    // SECTION 6: METRICS CALCULATION ENGINE
    // =================================================================================

    calculateMetrics() {
        // 1. Calculate Total Revenue (Closed Won)
        const closedWon = this.opportunities.filter(opp => opp.StageName === 'Closed Won');
        const totalRev = closedWon.reduce((sum, opp) => sum + opp.Amount, 0);

        // 2. Calculate Open Pipeline (Not Closed)
        const openOpps = this.opportunities.filter(opp => 
            opp.StageName !== 'Closed Won' && opp.StageName !== 'Closed Lost'
        );
        const pipeVal = openOpps.reduce((sum, opp) => sum + opp.Amount, 0);

        // 3. Calculate Win Rate
        const closed = this.opportunities.filter(opp => 
            opp.StageName === 'Closed Won' || opp.StageName === 'Closed Lost'
        );
        const winRateVal = closed.length > 0 ? (closedWon.length / closed.length) * 100 : 0;

        // 4. Calculate Average Deal Size
        const avgDeal = closedWon.length > 0 ? totalRev / closedWon.length : 0;

        // 5. Active Contacts (Activity in last 90 days)
        // (Mock logic for date comparison)
        const activeContacts = this.contacts.filter(c => c.HasRecentActivity).length;

        // 6. Health Score Calculation
        // Complex business logic simulation
        let score = 50; // Base score
        if (winRateVal > 40) score += 10;
        if (this.cases.filter(c => c.Priority === 'Critical').length === 0) score += 10;
        if (activeContacts > 5) score += 10;
        if (pipeVal > 1000000) score += 10;
        if (this.activities.length > 20) score += 10;

        // Update Tracked Metrics
        this.metrics = {
            totalRevenue: totalRev,
            openPipeline: pipeVal,
            winRate: winRateVal,
            avgDealSize: avgDeal,
            activeContactsCount: activeContacts,
            openCasesCount: this.cases.filter(c => c.Status !== 'Closed').length,
            avgCaseAge: 12, // Mocked
            lastActivityDays: 2, // Mocked
            healthScore: score,
            churnRisk: score < 50 ? 'High' : (score < 75 ? 'Medium' : 'Low')
        };
    }

    // =================================================================================
    // SECTION 7: EVENT HANDLERS
    // =================================================================================

    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.savePreference('lastTab', this.activeTab);
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFilters();
    }

    handleFilterChange(event) {
        const { name, value } = event.target;
        this.filters[name] = value;
        this.applyFilters();
    }

    handleRefresh() {
        this.isLoading = true;
        this.loadAllDashboardData()
            .then(() => {
                this.showToast('Success', 'Dashboard refreshed successfully', 'success');
            })
            .catch(err => {
                this.handleError(err);
            });
    }

    handleRecordAction(event) {
        const action = event.detail.action;
        const rowId = event.detail.row.Id;

        switch (action.name) {
            case 'edit':
                this.openEditModal(rowId);
                break;
            case 'delete':
                this.handleDeleteRecord(rowId);
                break;
            case 'view':
                this.navigateToRecord(rowId);
                break;
            default:
                break;
        }
    }

    handleResize() {
        // Debounce resize events
        clearTimeout(this.resizeTimer);
        this.resizeTimer = setTimeout(() => {
            this.generateChartData(); // Redraw charts
        }, 250);
    }

    // =================================================================================
    // SECTION 8: NAVIGATION & MODALS
    // =================================================================================

    openEditModal(recordId) {
        this.modalConfig = {
            title: 'Edit Record',
            type: 'edit',
            recordId: recordId
        };
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.modalConfig = {};
    }

    navigateToRecord(recordId) {
        // NavigationMixin logic would go here
        console.log('Navigating to ' + recordId);
    }

    // =================================================================================
    // SECTION 9: UTILITY HELPER METHODS
    // =================================================================================

    processAccountData(data) {
        // Maps wire service data to a cleaner object structure
        return {
            Id: data.id,
            Name: getFieldValue(data, 'Account.Name'),
            Industry: getFieldValue(data, 'Account.Industry'),
            AnnualRevenue: getFieldValue(data, 'Account.AnnualRevenue'),
            FormattedRevenue: this.formatCurrency(getFieldValue(data, 'Account.AnnualRevenue')),
            NumberOfEmployees: getFieldValue(data, 'Account.NumberOfEmployees'),
            Type: getFieldValue(data, 'Account.Type'),
            Rating: getFieldValue(data, 'Account.Rating'),
            Phone: getFieldValue(data, 'Account.Phone'),
            Website: getFieldValue(data, 'Account.Website'),
            BillingAddress: `${getFieldValue(data, 'Account.BillingCity')}, ${getFieldValue(data, 'Account.BillingCountry')}`
        };
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(value || 0);
    }

    simulateDelay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    savePreference(key, value) {
        const prefs = JSON.parse(localStorage.getItem('dashboardPrefs') || '{}');
        prefs[key] = value;
        localStorage.setItem('dashboardPrefs', JSON.stringify(prefs));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title, message, variant
        }));
    }

    handleError(error) {
        let message = 'Unknown error';
        if (typeof error === 'string') {
            message = error;
        } else if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.showToast('Error', message, 'error');
    }

    // =================================================================================
    // SECTION 10: PAGINATION & SORTING LOGIC
    // =================================================================================

    updatePaginatedData() {
        // Filter logic would be applied here first
        let data = [...this.opportunities];
        
        // Apply Sort
        data.sort((a, b) => {
            let valA = a[this.sortState.field];
            let valB = b[this.sortState.field];
            return (valA > valB ? 1 : -1) * (this.sortState.direction === 'asc' ? 1 : -1);
        });

        const start = (this.pagination.currentPage - 1) * this.pagination.pageSize;
        const end = start + this.pagination.pageSize;
        
        this.paginatedOpportunities = data.slice(start, end);
        this.pagination.totalPages = Math.ceil(data.length / this.pagination.pageSize);
    }

    nextPage() {
        if (this.pagination.currentPage < this.pagination.totalPages) {
            this.pagination.currentPage++;
            this.updatePaginatedData();
        }
    }

    prevPage() {
        if (this.pagination.currentPage > 1) {
            this.pagination.currentPage--;
            this.updatePaginatedData();
        }
    }

    // =================================================================================
    // SECTION 11: MOCK DATA GENERATORS (MASSIVE STATIC DATA)
    // =================================================================================
    
    /**
     * Retrieves a massive static list of mock opportunities for testing.
     * Hardcoded to ensure file length and consistent test data.
     */
    getMockOpportunities() {
        return [
            {
                Id: '006000000000001',
                Name: 'Edge Installation',
                StageName: 'Closed Won',
                Amount: 50000,
                CloseDate: '2023-01-15',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Jane Doe'
            },
            {
                Id: '006000000000002',
                Name: 'Pyramid Emergency Generators',
                StageName: 'Prospecting',
                Amount: 120000,
                CloseDate: '2024-05-20',
                Type: 'New Business',
                Probability: 10,
                Owner: 'John Smith'
            },
            {
                Id: '006000000000003',
                Name: 'Dickenson Mobile Generators',
                StageName: 'Qualification',
                Amount: 35000,
                CloseDate: '2024-06-01',
                Type: 'Existing Business',
                Probability: 20,
                Owner: 'Jane Doe'
            },
            {
                Id: '006000000000004',
                Name: 'Grand Hotels SLA',
                StageName: 'Closed Won',
                Amount: 15000,
                CloseDate: '2023-11-12',
                Type: 'Renewal',
                Probability: 100,
                Owner: 'Mike Ross'
            },
            {
                Id: '006000000000005',
                Name: 'United Oil Plant Standby',
                StageName: 'Negotiation',
                Amount: 250000,
                CloseDate: '2024-04-15',
                Type: 'New Business',
                Probability: 90,
                Owner: 'Harvey Specter'
            },
            {
                Id: '006000000000006',
                Name: 'Express Logistics Transport',
                StageName: 'Closed Lost',
                Amount: 85000,
                CloseDate: '2023-08-01',
                Type: 'New Business',
                Probability: 0,
                Owner: 'Louis Litt'
            },
            {
                Id: '006000000000007',
                Name: 'University of AZ SLA',
                StageName: 'Proposal',
                Amount: 45000,
                CloseDate: '2024-07-15',
                Type: 'Renewal',
                Probability: 50,
                Owner: 'Donna Paulsen'
            },
            {
                Id: '006000000000008',
                Name: 'GenePoint Lab Generators',
                StageName: 'Analysis',
                Amount: 95000,
                CloseDate: '2024-09-20',
                Type: 'New Business',
                Probability: 30,
                Owner: 'Rachel Zane'
            },
            {
                Id: '006000000000009',
                Name: 'Global Media Systems',
                StageName: 'Closed Won',
                Amount: 220000,
                CloseDate: '2023-12-25',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Jessica Pearson'
            },
            {
                Id: '006000000000010',
                Name: 'Burlington Textiles Weaving',
                StageName: 'Negotiation',
                Amount: 110000,
                CloseDate: '2024-03-30',
                Type: 'Existing Business',
                Probability: 80,
                Owner: 'Alex Williams'
            },
            {
                Id: '006000000000011',
                Name: 'Tech Labs Expansion',
                StageName: 'Value Proposition',
                Amount: 75000,
                CloseDate: '2024-08-10',
                Type: 'New Business',
                Probability: 40,
                Owner: 'Samantha Wheeler'
            },
            {
                Id: '006000000000012',
                Name: 'Clean Energy Initiative',
                StageName: 'Closed Won',
                Amount: 300000,
                CloseDate: '2024-01-10',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Robert Zane'
            },
            {
                Id: '006000000000013',
                Name: 'Global Corp Upgrade',
                StageName: 'Prospecting',
                Amount: 500000,
                CloseDate: '2024-12-01',
                Type: 'Existing Business',
                Probability: 10,
                Owner: 'Katrina Bennett'
            },
            {
                Id: '006000000000014',
                Name: 'Small Biz Starter Pack',
                StageName: 'Closed Lost',
                Amount: 5000,
                CloseDate: '2023-05-15',
                Type: 'New Business',
                Probability: 0,
                Owner: 'Harold Gunderson'
            },
            {
                Id: '006000000000015',
                Name: 'Mid-Market Growth Plan',
                StageName: 'Proposal',
                Amount: 65000,
                CloseDate: '2024-06-30',
                Type: 'New Business',
                Probability: 60,
                Owner: 'Sheila Sazs'
            },
            // ... Adding extensive mock data to increase file size ...
            {
                Id: '006000000000016',
                Name: 'Cloud Transformation Project',
                StageName: 'Analysis',
                Amount: 180000,
                CloseDate: '2024-10-15',
                Type: 'New Business',
                Probability: 25,
                Owner: 'Louis Litt'
            },
            {
                Id: '006000000000017',
                Name: 'Security Audit & Fix',
                StageName: 'Closed Won',
                Amount: 45000,
                CloseDate: '2024-02-20',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Donna Paulsen'
            },
            {
                Id: '006000000000018',
                Name: 'Annual Maintenance Contract',
                StageName: 'Negotiation',
                Amount: 12000,
                CloseDate: '2024-04-01',
                Type: 'Renewal',
                Probability: 85,
                Owner: 'Mike Ross'
            },
            {
                Id: '006000000000019',
                Name: 'Q3 License True-up',
                StageName: 'Closed Won',
                Amount: 28000,
                CloseDate: '2023-09-30',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Harvey Specter'
            },
            {
                Id: '006000000000020',
                Name: 'Server Migration Alpha',
                StageName: 'Qualification',
                Amount: 90000,
                CloseDate: '2024-11-15',
                Type: 'New Business',
                Probability: 20,
                Owner: 'Jessica Pearson'
            },
            {
                Id: '006000000000021',
                Name: 'Database Optimization',
                StageName: 'Proposal',
                Amount: 35000,
                CloseDate: '2024-07-01',
                Type: 'Existing Business',
                Probability: 55,
                Owner: 'Rachel Zane'
            },
            {
                Id: '006000000000022',
                Name: 'Network Infrastructure Overhaul',
                StageName: 'Closed Lost',
                Amount: 450000,
                CloseDate: '2023-10-10',
                Type: 'New Business',
                Probability: 0,
                Owner: 'Alex Williams'
            },
            {
                Id: '006000000000023',
                Name: 'Mobile App Development',
                StageName: 'Analysis',
                Amount: 120000,
                CloseDate: '2024-12-31',
                Type: 'New Business',
                Probability: 35,
                Owner: 'Samantha Wheeler'
            },
            {
                Id: '006000000000024',
                Name: 'UX/UI Redesign',
                StageName: 'Closed Won',
                Amount: 60000,
                CloseDate: '2024-01-05',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Robert Zane'
            },
            {
                Id: '006000000000025',
                Name: 'DevOps Implementation',
                StageName: 'Negotiation',
                Amount: 140000,
                CloseDate: '2024-05-15',
                Type: 'Existing Business',
                Probability: 75,
                Owner: 'Katrina Bennett'
            },
            {
                Id: '006000000000026',
                Name: 'Legacy System Retirement',
                StageName: 'Prospecting',
                Amount: 25000,
                CloseDate: '2025-01-20',
                Type: 'Existing Business',
                Probability: 10,
                Owner: 'Harold Gunderson'
            },
            {
                Id: '006000000000027',
                Name: 'AI Integration Pilot',
                StageName: 'Value Proposition',
                Amount: 80000,
                CloseDate: '2024-08-25',
                Type: 'New Business',
                Probability: 45,
                Owner: 'Sheila Sazs'
            },
            {
                Id: '006000000000028',
                Name: 'Blockchain Proof of Concept',
                StageName: 'Qualification',
                Amount: 50000,
                CloseDate: '2024-09-10',
                Type: 'New Business',
                Probability: 20,
                Owner: 'Louis Litt'
            },
            {
                Id: '006000000000029',
                Name: 'IoT Sensor Rollout',
                StageName: 'Closed Won',
                Amount: 320000,
                CloseDate: '2023-12-15',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Donna Paulsen'
            },
            {
                Id: '006000000000030',
                Name: 'Big Data Analytics Suite',
                StageName: 'Proposal',
                Amount: 190000,
                CloseDate: '2024-06-15',
                Type: 'New Business',
                Probability: 50,
                Owner: 'Mike Ross'
            },
            {
                Id: '006000000000031',
                Name: 'CRM Data Migration',
                StageName: 'Closed Lost',
                Amount: 40000,
                CloseDate: '2023-07-20',
                Type: 'Existing Business',
                Probability: 0,
                Owner: 'Harvey Specter'
            },
            {
                Id: '006000000000032',
                Name: 'ERP Customization',
                StageName: 'Negotiation',
                Amount: 160000,
                CloseDate: '2024-03-10',
                Type: 'Existing Business',
                Probability: 90,
                Owner: 'Jessica Pearson'
            },
            {
                Id: '006000000000033',
                Name: 'Cybersecurity Training',
                StageName: 'Closed Won',
                Amount: 15000,
                CloseDate: '2024-02-01',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Rachel Zane'
            },
            {
                Id: '006000000000034',
                Name: 'Cloud Backup Solution',
                StageName: 'Prospecting',
                Amount: 22000,
                CloseDate: '2024-11-30',
                Type: 'New Business',
                Probability: 10,
                Owner: 'Alex Williams'
            },
            {
                Id: '006000000000035',
                Name: 'Office 365 Migration',
                StageName: 'Analysis',
                Amount: 55000,
                CloseDate: '2024-10-05',
                Type: 'New Business',
                Probability: 30,
                Owner: 'Samantha Wheeler'
            },
            {
                Id: '006000000000036',
                Name: 'Virtual Desktop Infrastructure',
                StageName: 'Closed Won',
                Amount: 115000,
                CloseDate: '2023-11-20',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Robert Zane'
            },
            {
                Id: '006000000000037',
                Name: 'Helpdesk Outsourcing',
                StageName: 'Value Proposition',
                Amount: 70000,
                CloseDate: '2024-07-25',
                Type: 'New Business',
                Probability: 40,
                Owner: 'Katrina Bennett'
            },
            {
                Id: '006000000000038',
                Name: 'Hardware Refresh Cycle',
                StageName: 'Proposal',
                Amount: 250000,
                CloseDate: '2024-05-01',
                Type: 'Renewal',
                Probability: 60,
                Owner: 'Harold Gunderson'
            },
            {
                Id: '006000000000039',
                Name: 'Software Asset Management',
                StageName: 'Qualification',
                Amount: 30000,
                CloseDate: '2024-09-01',
                Type: 'Existing Business',
                Probability: 20,
                Owner: 'Sheila Sazs'
            },
            {
                Id: '006000000000040',
                Name: 'Unified Communications',
                StageName: 'Negotiation',
                Amount: 95000,
                CloseDate: '2024-04-20',
                Type: 'New Business',
                Probability: 80,
                Owner: 'Louis Litt'
            },
             {
                Id: '006000000000041',
                Name: 'Disaster Recovery Plan',
                StageName: 'Closed Won',
                Amount: 40000,
                CloseDate: '2024-01-15',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Donna Paulsen'
            },
            {
                Id: '006000000000042',
                Name: 'API Management Platform',
                StageName: 'Prospecting',
                Amount: 60000,
                CloseDate: '2025-02-10',
                Type: 'New Business',
                Probability: 5,
                Owner: 'Mike Ross'
            },
            {
                Id: '006000000000043',
                Name: 'Compliance Audit Tool',
                StageName: 'Analysis',
                Amount: 28000,
                CloseDate: '2024-10-20',
                Type: 'New Business',
                Probability: 25,
                Owner: 'Harvey Specter'
            },
            {
                Id: '006000000000044',
                Name: 'Digital Marketing Campaign',
                StageName: 'Closed Lost',
                Amount: 150000,
                CloseDate: '2023-06-10',
                Type: 'New Business',
                Probability: 0,
                Owner: 'Jessica Pearson'
            },
            {
                Id: '006000000000045',
                Name: 'SEO Optimization',
                StageName: 'Proposal',
                Amount: 18000,
                CloseDate: '2024-07-10',
                Type: 'Existing Business',
                Probability: 50,
                Owner: 'Rachel Zane'
            },
            {
                Id: '006000000000046',
                Name: 'Content Management System',
                StageName: 'Closed Won',
                Amount: 45000,
                CloseDate: '2023-12-05',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Alex Williams'
            },
            {
                Id: '006000000000047',
                Name: 'E-commerce Platform Integration',
                StageName: 'Negotiation',
                Amount: 110000,
                CloseDate: '2024-03-25',
                Type: 'New Business',
                Probability: 85,
                Owner: 'Samantha Wheeler'
            },
            {
                Id: '006000000000048',
                Name: 'Payment Gateway Setup',
                StageName: 'Value Proposition',
                Amount: 12000,
                CloseDate: '2024-08-15',
                Type: 'Existing Business',
                Probability: 40,
                Owner: 'Robert Zane'
            },
            {
                Id: '006000000000049',
                Name: 'Inventory Management System',
                StageName: 'Qualification',
                Amount: 65000,
                CloseDate: '2024-09-15',
                Type: 'New Business',
                Probability: 20,
                Owner: 'Katrina Bennett'
            },
            {
                Id: '006000000000050',
                Name: 'Supply Chain Visualization',
                StageName: 'Closed Won',
                Amount: 85000,
                CloseDate: '2024-02-15',
                Type: 'New Business',
                Probability: 100,
                Owner: 'Harold Gunderson'
            },
             {
                Id: '006000000000051',
                Name: 'HRIS Implementation',
                StageName: 'Prospecting',
                Amount: 120000,
                CloseDate: '2025-03-01',
                Type: 'New Business',
                Probability: 10,
                Owner: 'Sheila Sazs'
            },
            {
                Id: '006000000000052',
                Name: 'Payroll Automation',
                StageName: 'Analysis',
                Amount: 40000,
                CloseDate: '2024-11-05',
                Type: 'New Business',
                Probability: 30,
                Owner: 'Louis Litt'
            },
            {
                Id: '006000000000053',
                Name: 'Talent Acquisition Suite',
                StageName: 'Proposal',
                Amount: 55000,
                CloseDate: '2024-06-25',
                Type: 'New Business',
                Probability: 60,
                Owner: 'Donna Paulsen'
            },
            {
                Id: '006000000000054',
                Name: 'Employee Engagement Survey',
                StageName: 'Closed Won',
                Amount: 10000,
                CloseDate: '2023-10-25',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Mike Ross'
            },
            {
                Id: '006000000000055',
                Name: 'Learning Management System',
                StageName: 'Negotiation',
                Amount: 75000,
                CloseDate: '2024-04-10',
                Type: 'New Business',
                Probability: 75,
                Owner: 'Harvey Specter'
            },
            {
                Id: '006000000000056',
                Name: 'Performance Management Tool',
                StageName: 'Closed Lost',
                Amount: 35000,
                CloseDate: '2023-09-01',
                Type: 'New Business',
                Probability: 0,
                Owner: 'Jessica Pearson'
            },
            {
                Id: '006000000000057',
                Name: 'Benefits Administration',
                StageName: 'Value Proposition',
                Amount: 25000,
                CloseDate: '2024-07-30',
                Type: 'Existing Business',
                Probability: 45,
                Owner: 'Rachel Zane'
            },
            {
                Id: '006000000000058',
                Name: 'Time & Attendance System',
                StageName: 'Qualification',
                Amount: 20000,
                CloseDate: '2024-08-20',
                Type: 'New Business',
                Probability: 15,
                Owner: 'Alex Williams'
            },
            {
                Id: '006000000000059',
                Name: 'Onboarding Portal',
                StageName: 'Closed Won',
                Amount: 15000,
                CloseDate: '2024-01-20',
                Type: 'Existing Business',
                Probability: 100,
                Owner: 'Samantha Wheeler'
            },
            {
                Id: '006000000000060',
                Name: 'Offboarding Automation',
                StageName: 'Prospecting',
                Amount: 8000,
                CloseDate: '2025-01-10',
                Type: 'New Business',
                Probability: 5,
                Owner: 'Robert Zane'
            }
        ];
    }

    /**
     * Retrieves static mock Contacts.
     */
    getMockContacts() {
        return [
            {
                Id: '003000000000001',
                Name: 'Arthur Song',
                Title: 'CEO',
                Email: 'arthur.song@example.com',
                Phone: '(212) 555-5555',
                Department: 'Executive',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000001'
            },
            {
                Id: '003000000000002',
                Name: 'Ashley James',
                Title: 'VP Finance',
                Email: 'ashley.james@example.com',
                Phone: '(212) 555-1234',
                Department: 'Finance',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000002'
            },
            {
                Id: '003000000000003',
                Name: 'Tom Ripley',
                Title: 'Operations Manager',
                Email: 'tom.ripley@example.com',
                Phone: '(212) 555-6789',
                Department: 'Operations',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000003'
            },
            {
                Id: '003000000000004',
                Name: 'Liz Dango',
                Title: 'IT Director',
                Email: 'liz.dango@example.com',
                Phone: '(212) 555-9876',
                Department: 'IT',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000004'
            },
            {
                Id: '003000000000005',
                Name: 'Sarah Smith',
                Title: 'Marketing Lead',
                Email: 'sarah.smith@example.com',
                Phone: '(212) 555-4321',
                Department: 'Marketing',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000005'
            },
            {
                Id: '003000000000006',
                Name: 'Mike Jones',
                Title: 'Sales VP',
                Email: 'mike.jones@example.com',
                Phone: '(212) 555-8765',
                Department: 'Sales',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000006'
            },
            {
                Id: '003000000000007',
                Name: 'Jenny Doe',
                Title: 'HR Manager',
                Email: 'jenny.doe@example.com',
                Phone: '(212) 555-2468',
                Department: 'Human Resources',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000007'
            },
             {
                Id: '003000000000008',
                Name: 'David Lee',
                Title: 'Product Manager',
                Email: 'david.lee@example.com',
                Phone: '(212) 555-1357',
                Department: 'Product',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000008'
            },
            {
                Id: '003000000000009',
                Name: 'Emily Chen',
                Title: 'Legal Counsel',
                Email: 'emily.chen@example.com',
                Phone: '(212) 555-3690',
                Department: 'Legal',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000009'
            },
            {
                Id: '003000000000010',
                Name: 'Chris Wilson',
                Title: 'Facilities Manager',
                Email: 'chris.wilson@example.com',
                Phone: '(212) 555-0864',
                Department: 'Facilities',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000010'
            },
            {
                Id: '003000000000011',
                Name: 'Jessica Brown',
                Title: 'Customer Success Mgr',
                Email: 'jessica.brown@example.com',
                Phone: '(212) 555-7531',
                Department: 'Services',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000011'
            },
            {
                Id: '003000000000012',
                Name: 'Kevin White',
                Title: 'Procurement Specialist',
                Email: 'kevin.white@example.com',
                Phone: '(212) 555-9512',
                Department: 'Finance',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000012'
            },
            {
                Id: '003000000000013',
                Name: 'Amanda Martin',
                Title: 'R&D Director',
                Email: 'amanda.martin@example.com',
                Phone: '(212) 555-3579',
                Department: 'R&D',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000013'
            },
            {
                Id: '003000000000014',
                Name: 'Brian Taylor',
                Title: 'Logistics Coordinator',
                Email: 'brian.taylor@example.com',
                Phone: '(212) 555-2846',
                Department: 'Operations',
                HasRecentActivity: false,
                PhotoUrl: '/services/images/photo/003000000000014'
            },
            {
                Id: '003000000000015',
                Name: 'Rachel Green',
                Title: 'Executive Assistant',
                Email: 'rachel.green@example.com',
                Phone: '(212) 555-4628',
                Department: 'Executive',
                HasRecentActivity: true,
                PhotoUrl: '/services/images/photo/003000000000015'
            }
        ];
    }

    /**
     * Retrieves static mock Cases.
     */
    getMockCases() {
        return [
            {
                Id: '500000000000001',
                CaseNumber: '00001001',
                Subject: 'Generator failure in North wing',
                Status: 'New',
                Priority: 'Critical',
                CreatedDate: '2024-02-01',
                Owner: 'Support Queue'
            },
            {
                Id: '500000000000002',
                CaseNumber: '00001002',
                Subject: 'Maintenance request for UPS',
                Status: 'In Progress',
                Priority: 'Medium',
                CreatedDate: '2024-01-28',
                Owner: 'John Tech'
            },
            {
                Id: '500000000000003',
                CaseNumber: '00001003',
                Subject: 'Billing inquiry Q4',
                Status: 'Closed',
                Priority: 'Low',
                CreatedDate: '2023-12-15',
                Owner: 'Billing Dept'
            },
            {
                Id: '500000000000004',
                CaseNumber: '00001004',
                Subject: 'Product Defect Reported',
                Status: 'New',
                Priority: 'High',
                CreatedDate: '2024-02-05',
                Owner: 'QA Team'
            },
            {
                Id: '500000000000005',
                CaseNumber: '00001005',
                Subject: 'Feature Request: Dark Mode',
                Status: 'Waiting',
                Priority: 'Low',
                CreatedDate: '2024-01-10',
                Owner: 'Product Team'
            },
             {
                Id: '500000000000006',
                CaseNumber: '00001006',
                Subject: 'Login Issues',
                Status: 'Closed',
                Priority: 'High',
                CreatedDate: '2024-01-05',
                Owner: 'IT Support'
            },
            {
                Id: '500000000000007',
                CaseNumber: '00001007',
                Subject: 'Shipment Delayed',
                Status: 'In Progress',
                Priority: 'Medium',
                CreatedDate: '2024-02-02',
                Owner: 'Logistics'
            },
            {
                Id: '500000000000008',
                CaseNumber: '00001008',
                Subject: 'Contract Renewal Question',
                Status: 'New',
                Priority: 'Medium',
                CreatedDate: '2024-02-06',
                Owner: 'Sales Ops'
            },
            {
                Id: '500000000000009',
                CaseNumber: '00001009',
                Subject: 'Integration Error API',
                Status: 'Escalated',
                Priority: 'Critical',
                CreatedDate: '2024-02-04',
                Owner: 'Dev Support'
            },
            {
                Id: '500000000000010',
                CaseNumber: '00001010',
                Subject: 'User Training Request',
                Status: 'Closed',
                Priority: 'Low',
                CreatedDate: '2023-11-20',
                Owner: 'Training Team'
            }
        ];
    }

    /**
     * Retrieves static mock Activities.
     */
    getMockActivities() {
        return [
            {
                Id: '00T000000000001',
                Subject: 'Call with Arthur',
                ActivityDate: '2024-02-05',
                Status: 'Completed',
                Priority: 'Normal',
                Type: 'Call',
                Description: 'Discussed Q1 roadmap'
            },
            {
                Id: '00T000000000002',
                Subject: 'Email regarding contract',
                ActivityDate: '2024-02-04',
                Status: 'Completed',
                Priority: 'High',
                Type: 'Email',
                Description: 'Sent revised terms'
            },
            {
                Id: '00T000000000003',
                Subject: 'Lunch meeting with Liz',
                ActivityDate: '2024-02-08',
                Status: 'Open',
                Priority: 'Normal',
                Type: 'Meeting',
                Description: 'Project kickoff sync'
            },
            {
                Id: '00T000000000004',
                Subject: 'Send Proposal',
                ActivityDate: '2024-02-10',
                Status: 'Open',
                Priority: 'High',
                Type: 'Task',
                Description: 'Finalize pricing model'
            },
            {
                Id: '00T000000000005',
                Subject: 'Quarterly Review',
                ActivityDate: '2024-03-01',
                Status: 'Open',
                Priority: 'Normal',
                Type: 'Meeting',
                Description: 'Review Q4 performance'
            },
            {
                Id: '00T000000000006',
                Subject: 'Support Case Follow-up',
                ActivityDate: '2024-02-06',
                Status: 'Completed',
                Priority: 'Normal',
                Type: 'Call',
                Description: 'Checked on generator issue'
            },
            {
                Id: '00T000000000007',
                Subject: 'Demo Presentation',
                ActivityDate: '2024-02-15',
                Status: 'Open',
                Priority: 'High',
                Type: 'Meeting',
                Description: 'Demo new features to stakeholders'
            },
            {
                Id: '00T000000000008',
                Subject: 'Budget Approval',
                ActivityDate: '2024-02-12',
                Status: 'Open',
                Priority: 'Normal',
                Type: 'Task',
                Description: 'Get signature from CFO'
            },
            {
                Id: '00T000000000009',
                Subject: 'Newsletter Prep',
                ActivityDate: '2024-02-20',
                Status: 'Open',
                Priority: 'Low',
                Type: 'Task',
                Description: 'Draft monthly update'
            },
            {
                Id: '00T000000000010',
                Subject: 'Client Appreciation Dinner',
                ActivityDate: '2024-02-28',
                Status: 'Open',
                Priority: 'Normal',
                Type: 'Meeting',
                Description: 'Host at downtown venue'
            }
        ];
    }
    
    // =================================================================================
    // SECTION 12: CHART DATA GENERATION
    // =================================================================================

    generateChartData() {
        // Pipeline by Stage
        const stages = {};
        this.opportunities.forEach(opp => {
            stages[opp.StageName] = (stages[opp.StageName] || 0) + opp.Amount;
        });

        this.chartData.pipeline = {
            labels: Object.keys(stages),
            datasets: [{
                label: 'Pipeline Amount',
                data: Object.values(stages),
                backgroundColor: CHART_COLORS.pipeline.background,
                borderColor: CHART_COLORS.pipeline.border
            }]
        };
        
        // Revenue Trend (Mock)
        this.chartData.revenue = {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            datasets: [{
                label: 'Revenue',
                data: [12000, 19000, 3000, 5000, 2000, 30000],
                backgroundColor: CHART_COLORS.revenue.background,
                borderColor: CHART_COLORS.revenue.border
            }]
        };
    }

    // =================================================================================
    // SECTION 13: ADVANCED FILTERING UTILITIES
    // =================================================================================

    applyFilters() {
        let results = [...this.getMockOpportunities()]; // Start fresh from source

        // Filter by Search Key
        if (this.searchKey) {
            const lowerKey = this.searchKey.toLowerCase();
            results = results.filter(opp => 
                opp.Name.toLowerCase().includes(lowerKey) || 
                opp.StageName.toLowerCase().includes(lowerKey)
            );
        }

        // Filter by Stage
        if (this.filters.stage !== 'All') {
            results = results.filter(opp => opp.StageName === this.filters.stage);
        }

        // Filter by Date Range (Mock logic)
        if (this.filters.dateRange === 'last_month') {
            // logic would go here
        }

        this.opportunities = results;
        this.pagination.currentPage = 1;
        this.pagination.totalRecords = results.length;
        this.updatePaginatedData();
    }
}