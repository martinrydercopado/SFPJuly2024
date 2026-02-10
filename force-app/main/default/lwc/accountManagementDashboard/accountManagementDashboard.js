import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Mock field imports (using standard Account fields)
const FIELDS = [
    'Account.Name',
    'Account.Industry',
    'Account.AnnualRevenue',
    'Account.NumberOfEmployees',
    'Account.Type',
    'Account.Rating',
    'Account.Phone',
    'Account.Website',
    'Account.BillingCity',
    'Account.BillingState',
    'Account.BillingCountry'
];

export default class AccountManagementDashboard extends LightningElement {
    @api recordId;
    @track accountData = {};
    @track opportunities = [];
    @track contacts = [];
    @track cases = [];
    @track activities = [];
    @track metrics = {};
    @track isLoading = true;
    @track error;
    @track activeTab = 'overview';
    @track showModal = false;
    @track modalType = '';
    @track selectedRecord = null;
    @track chartData = {};
    @track filterCriteria = {
        dateRange: 'last90days',
        status: 'all',
        priority: 'all'
    };

    // Pagination properties
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;

    // Sorting properties
    @track sortBy = 'Name';
    @track sortDirection = 'asc';

    // Search and filter
    @track searchKey = '';
    @track appliedFilters = [];

    // Dashboard configuration
    @track dashboardConfig = {
        showOpportunities: true,
        showContacts: true,
        showCases: true,
        showActivities: true,
        showMetrics: true,
        refreshInterval: 300000 // 5 minutes
    };

    // Wire service to get account data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = this.formatAccountData(data);
            this.loadDashboardData();
        } else if (error) {
            this.handleError(error);
        }
    }

    // Lifecycle hooks
    connectedCallback() {
        this.initializeDashboard();
        this.setupRefreshInterval();
    }

    disconnectedCallback() {
        this.clearRefreshInterval();
    }

    renderedCallback() {
        this.updateChartRendering();
    }

    // Initialization methods
    initializeDashboard() {
        try {
            this.loadUserPreferences();
            this.validatePermissions();
            this.setupEventListeners();
            this.initializeMetrics();
        } catch (error) {
            this.handleError(error);
        }
    }

    loadUserPreferences() {
        const savedPreferences = localStorage.getItem('accountDashboardPreferences');
        if (savedPreferences) {
            try {
                const preferences = JSON.parse(savedPreferences);
                this.dashboardConfig = { ...this.dashboardConfig, ...preferences };
                this.filterCriteria = preferences.filters || this.filterCriteria;
            } catch (error) {
                console.error('Error loading preferences:', error);
            }
        }
    }

    saveUserPreferences() {
        const preferences = {
            ...this.dashboardConfig,
            filters: this.filterCriteria
        };
        localStorage.setItem('accountDashboardPreferences', JSON.stringify(preferences));
    }

    validatePermissions() {
        // Mock permission validation
        this.hasEditPermission = true;
        this.hasDeletePermission = true;
        this.hasCreatePermission = true;
    }

    setupEventListeners() {
        window.addEventListener('resize', this.handleResize.bind(this));
        document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
    }

    setupRefreshInterval() {
        if (this.dashboardConfig.refreshInterval > 0) {
            this.refreshIntervalId = setInterval(() => {
                this.refreshDashboard();
            }, this.dashboardConfig.refreshInterval);
        }
    }

    clearRefreshInterval() {
        if (this.refreshIntervalId) {
            clearInterval(this.refreshIntervalId);
        }
    }

    // Data loading methods
    async loadDashboardData() {
        this.isLoading = true;
        try {
            await Promise.all([
                this.loadOpportunities(),
                this.loadContacts(),
                this.loadCases(),
                this.loadActivities(),
                this.calculateMetrics()
            ]);
            this.updateChartData();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadOpportunities() {
        // Mock opportunity data
        this.opportunities = this.generateMockOpportunities();
        this.totalRecords = this.opportunities.length;
    }

    async loadContacts() {
        // Mock contact data
        this.contacts = this.generateMockContacts();
    }

    async loadCases() {
        // Mock case data
        this.cases = this.generateMockCases();
    }

    async loadActivities() {
        // Mock activity data
        this.activities = this.generateMockActivities();
    }

    async calculateMetrics() {
        this.metrics = {
            totalRevenue: this.calculateTotalRevenue(),
            openOpportunities: this.countOpenOpportunities(),
            closedWon: this.countClosedWon(),
            averageDealSize: this.calculateAverageDealSize(),
            winRate: this.calculateWinRate(),
            salesCycle: this.calculateAverageSalesCycle(),
            customerSatisfaction: this.calculateCustomerSatisfaction(),
            activeContacts: this.countActiveContacts(),
            openCases: this.countOpenCases(),
            responseTime: this.calculateAverageResponseTime()
        };
    }

    // Mock data generation
    generateMockOpportunities() {
        const opportunities = [];
        const stages = ['Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost'];
        const types = ['New Business', 'Existing Business', 'Renewal'];
        
        for (let i = 0; i < 25; i++) {
            opportunities.push({
                Id: `006${i.toString().padStart(15, '0')}`,
                Name: `Opportunity ${i + 1}`,
                StageName: stages[Math.floor(Math.random() * stages.length)],
                Amount: Math.floor(Math.random() * 1000000) + 10000,
                CloseDate: this.getRandomDate(),
                Probability: Math.floor(Math.random() * 100),
                Type: types[Math.floor(Math.random() * types.length)],
                NextStep: this.getRandomNextStep(),
                LastModifiedDate: new Date().toISOString()
            });
        }
        return opportunities;
    }

    generateMockContacts() {
        const contacts = [];
        const titles = ['CEO', 'CTO', 'VP Sales', 'Director', 'Manager', 'Analyst'];
        
        for (let i = 0; i < 15; i++) {
            contacts.push({
                Id: `003${i.toString().padStart(15, '0')}`,
                Name: `Contact ${i + 1}`,
                Title: titles[Math.floor(Math.random() * titles.length)],
                Email: `contact${i + 1}@example.com`,
                Phone: this.generatePhoneNumber(),
                LastActivityDate: this.getRandomDate(),
                EngagementScore: Math.floor(Math.random() * 100)
            });
        }
        return contacts;
    }

    generateMockCases() {
        const cases = [];
        const statuses = ['New', 'In Progress', 'Waiting on Customer', 'Escalated', 'Closed'];
        const priorities = ['Low', 'Medium', 'High', 'Critical'];
        
        for (let i = 0; i < 20; i++) {
            cases.push({
                Id: `500${i.toString().padStart(15, '0')}`,
                CaseNumber: `CASE-${(1000 + i).toString()}`,
                Subject: `Case Subject ${i + 1}`,
                Status: statuses[Math.floor(Math.random() * statuses.length)],
                Priority: priorities[Math.floor(Math.random() * priorities.length)],
                CreatedDate: this.getRandomDate(),
                LastModifiedDate: new Date().toISOString()
            });
        }
        return cases;
    }

    generateMockActivities() {
        const activities = [];
        const types = ['Call', 'Email', 'Meeting', 'Task'];
        
        for (let i = 0; i < 30; i++) {
            activities.push({
                Id: `00T${i.toString().padStart(15, '0')}`,
                Subject: `Activity ${i + 1}`,
                Type: types[Math.floor(Math.random() * types.length)],
                Status: Math.random() > 0.5 ? 'Completed' : 'Open',
                ActivityDate: this.getRandomDate(),
                Description: `Description for activity ${i + 1}`
            });
        }
        return activities;
    }

    // Calculation methods
    calculateTotalRevenue() {
        return this.opportunities
            .filter(opp => opp.StageName === 'Closed Won')
            .reduce((sum, opp) => sum + opp.Amount, 0);
    }

    countOpenOpportunities() {
        return this.opportunities.filter(opp => 
            opp.StageName !== 'Closed Won' && opp.StageName !== 'Closed Lost'
        ).length;
    }

    countClosedWon() {
        return this.opportunities.filter(opp => opp.StageName === 'Closed Won').length;
    }

    calculateAverageDealSize() {
        const closedWon = this.opportunities.filter(opp => opp.StageName === 'Closed Won');
        if (closedWon.length === 0) return 0;
        return closedWon.reduce((sum, opp) => sum + opp.Amount, 0) / closedWon.length;
    }

    calculateWinRate() {
        const closed = this.opportunities.filter(opp => 
            opp.StageName === 'Closed Won' || opp.StageName === 'Closed Lost'
        );
        if (closed.length === 0) return 0;
        const won = closed.filter(opp => opp.StageName === 'Closed Won').length;
        return (won / closed.length) * 100;
    }

    calculateAverageSalesCycle() {
        // Mock calculation - returns days
        return 45;
    }

    calculateCustomerSatisfaction() {
        // Mock calculation - returns percentage
        return 87;
    }

    countActiveContacts() {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return this.contacts.filter(contact => 
            new Date(contact.LastActivityDate) > thirtyDaysAgo
        ).length;
    }

    countOpenCases() {
        return this.cases.filter(c => c.Status !== 'Closed').length;
    }

    calculateAverageResponseTime() {
        // Mock calculation - returns hours
        return 4.5;
    }

    // Chart data methods
    updateChartData() {
        this.chartData = {
            opportunityPipeline: this.generatePipelineChartData(),
            revenueByMonth: this.generateRevenueChartData(),
            casesByPriority: this.generateCasePriorityData(),
            activityTrend: this.generateActivityTrendData()
        };
    }

    generatePipelineChartData() {
        const stageGroups = this.opportunities.reduce((acc, opp) => {
            acc[opp.StageName] = (acc[opp.StageName] || 0) + opp.Amount;
            return acc;
        }, {});

        return {
            labels: Object.keys(stageGroups),
            datasets: [{
                label: 'Pipeline Value',
                data: Object.values(stageGroups)
            }]
        };
    }

    generateRevenueChartData() {
        // Mock monthly revenue data
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
        const data = months.map(() => Math.floor(Math.random() * 500000));

        return {
            labels: months,
            datasets: [{
                label: 'Revenue',
                data: data
            }]
        };
    }

    generateCasePriorityData() {
        const priorityGroups = this.cases.reduce((acc, c) => {
            acc[c.Priority] = (acc[c.Priority] || 0) + 1;
            return acc;
        }, {});

        return {
            labels: Object.keys(priorityGroups),
            datasets: [{
                label: 'Cases',
                data: Object.values(priorityGroups)
            }]
        };
    }

    generateActivityTrendData() {
        // Mock activity trend over last 7 days
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const data = days.map(() => Math.floor(Math.random() * 20));

        return {
            labels: days,
            datasets: [{
                label: 'Activities',
                data: data
            }]
        };
    }

    // Event handlers
    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.saveUserPreferences();
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFiltersAndSearch();
    }

    handleFilterChange(event) {
        const { name, value } = event.target;
        this.filterCriteria[name] = value;
        this.applyFiltersAndSearch();
        this.saveUserPreferences();
    }

    handleSort(event) {
        const fieldName = event.currentTarget.dataset.field;
        if (this.sortBy === fieldName) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortBy = fieldName;
            this.sortDirection = 'asc';
        }
        this.applySorting();
    }

    handlePageChange(event) {
        this.currentPage = parseInt(event.target.value, 10);
        this.updatePaginatedData();
    }

    handleRefresh() {
        this.refreshDashboard();
    }

    handleResize() {
        this.updateChartRendering();
    }

    handleVisibilityChange() {
        if (document.hidden) {
            this.clearRefreshInterval();
        } else {
            this.setupRefreshInterval();
            this.refreshDashboard();
        }
    }

    handleRecordClick(event) {
        const recordId = event.currentTarget.dataset.id;
        const recordType = event.currentTarget.dataset.type;
        this.openRecordDetail(recordId, recordType);
    }

    handleCreateNew(event) {
        const recordType = event.currentTarget.dataset.type;
        this.openCreateModal(recordType);
    }

    handleEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        const recordType = event.currentTarget.dataset.type;
        this.openEditModal(recordId, recordType);
    }

    handleDelete(event) {
        const recordId = event.currentTarget.dataset.id;
        this.confirmDelete(recordId);
    }

    handleModalClose() {
        this.showModal = false;
        this.selectedRecord = null;
        this.modalType = '';
    }

    handleModalSave(event) {
        const data = event.detail;
        this.saveRecord(data);
    }

    // Data manipulation methods
    applyFiltersAndSearch() {
        let filteredData = [...this.opportunities];

        // Apply search
        if (this.searchKey) {
            filteredData = filteredData.filter(record =>
                record.Name.toLowerCase().includes(this.searchKey) ||
                record.StageName.toLowerCase().includes(this.searchKey)
            );
        }

        // Apply filters
        if (this.filterCriteria.status !== 'all') {
            filteredData = filteredData.filter(record =>
                record.StageName === this.filterCriteria.status
            );
        }

        if (this.filterCriteria.dateRange !== 'all') {
            filteredData = this.applyDateFilter(filteredData);
        }

        this.filteredOpportunities = filteredData;
        this.totalRecords = filteredData.length;
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    applyDateFilter(data) {
        const now = new Date();
        let cutoffDate = new Date();

        switch (this.filterCriteria.dateRange) {
            case 'last7days':
                cutoffDate.setDate(now.getDate() - 7);
                break;
            case 'last30days':
                cutoffDate.setDate(now.getDate() - 30);
                break;
            case 'last90days':
                cutoffDate.setDate(now.getDate() - 90);
                break;
            default:
                return data;
        }

        return data.filter(record =>
            new Date(record.LastModifiedDate) > cutoffDate
        );
    }

    applySorting() {
        const sortedData = [...this.filteredOpportunities];
        const isAsc = this.sortDirection === 'asc';

        sortedData.sort((a, b) => {
            const aVal = a[this.sortBy];
            const bVal = b[this.sortBy];

            if (typeof aVal === 'string') {
                return isAsc ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
            } else {
                return isAsc ? aVal - bVal : bVal - aVal;
            }
        });

        this.filteredOpportunities = sortedData;
        this.updatePaginatedData();
    }

    updatePaginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedOpportunities = this.filteredOpportunities.slice(start, end);
    }

    // Modal operations
    openRecordDetail(recordId, recordType) {
        this.selectedRecord = this.findRecord(recordId, recordType);
        this.modalType = 'detail';
        this.showModal = true;
    }

    openCreateModal(recordType) {
        this.selectedRecord = null;
        this.modalType = `create-${recordType}`;
        this.showModal = true;
    }

    openEditModal(recordId, recordType) {
        this.selectedRecord = this.findRecord(recordId, recordType);
        this.modalType = `edit-${recordType}`;
        this.showModal = true;
    }

    findRecord(recordId, recordType) {
        let collection;
        switch (recordType) {
            case 'opportunity':
                collection = this.opportunities;
                break;
            case 'contact':
                collection = this.contacts;
                break;
            case 'case':
                collection = this.cases;
                break;
            default:
                return null;
        }
        return collection.find(r => r.Id === recordId);
    }

    async saveRecord(data) {
        try {
            this.isLoading = true;
            // Mock save operation
            await this.simulateApiCall();
            this.showToast('Success', 'Record saved successfully', 'success');
            this.handleModalClose();
            this.refreshDashboard();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async confirmDelete(recordId) {
        if (confirm('Are you sure you want to delete this record?')) {
            try {
                this.isLoading = true;
                // Mock delete operation
                await this.simulateApiCall();
                this.showToast('Success', 'Record deleted successfully', 'success');
                this.refreshDashboard();
            } catch (error) {
                this.handleError(error);
            } finally {
                this.isLoading = false;
            }
        }
    }

    // Utility methods
    async refreshDashboard() {
        try {
            await this.loadDashboardData();
            this.showToast('Success', 'Dashboard refreshed', 'success');
        } catch (error) {
            this.handleError(error);
        }
    }

    formatAccountData(data) {
        return {
            id: data.id,
            name: getFieldValue(data, 'Account.Name'),
            industry: getFieldValue(data, 'Account.Industry'),
            revenue: getFieldValue(data, 'Account.AnnualRevenue'),
            employees: getFieldValue(data, 'Account.NumberOfEmployees'),
            type: getFieldValue(data, 'Account.Type'),
            rating: getFieldValue(data, 'Account.Rating'),
            phone: getFieldValue(data, 'Account.Phone'),
            website: getFieldValue(data, 'Account.Website'),
            city: getFieldValue(data, 'Account.BillingCity'),
            state: getFieldValue(data, 'Account.BillingState'),
            country: getFieldValue(data, 'Account.BillingCountry')
        };
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value || 0);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        }).format(date);
    }

    formatPercentage(value) {
        return `${(value || 0).toFixed(1)}%`;
    }

    getRandomDate() {
        const start = new Date(2024, 0, 1);
        const end = new Date(2026, 11, 31);
        return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime())).toISOString();
    }

    getRandomNextStep() {
        const steps = [
            'Schedule demo',
            'Send proposal',
            'Follow up call',
            'Contract negotiation',
            'Final approval'
        ];
        return steps[Math.floor(Math.random() * steps.length)];
    }

    generatePhoneNumber() {
        return `+1-${Math.floor(Math.random() * 900 + 100)}-${Math.floor(Math.random() * 900 + 100)}-${Math.floor(Math.random() * 9000 + 1000)}`;
    }

    simulateApiCall() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }

    updateChartRendering() {
        // Mock chart update logic
        if (this.template.querySelector('.chart-container')) {
            // Chart rendering would happen here
        }
    }

    initializeMetrics() {
        this.metrics = {
            totalRevenue: 0,
            openOpportunities: 0,
            closedWon: 0,
            averageDealSize: 0,
            winRate: 0,
            salesCycle: 0,
            customerSatisfaction: 0,
            activeContacts: 0,
            openCases: 0,
            responseTime: 0
        };
    }

    handleError(error) {
        console.error('Dashboard Error:', error);
        this.error = error;
        const message = error.body?.message || error.message || 'An unknown error occurred';
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters for template
    get hasOpportunities() {
        return this.opportunities && this.opportunities.length > 0;
    }

    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }

    get hasCases() {
        return this.cases && this.cases.length > 0;
    }

    get hasActivities() {
        return this.activities && this.activities.length > 0;
    }

    get formattedRevenue() {
        return this.formatCurrency(this.metrics.totalRevenue);
    }

    get formattedAverageDeal() {
        return this.formatCurrency(this.metrics.averageDealSize);
    }

    get formattedWinRate() {
        return this.formatPercentage(this.metrics.winRate);
    }

    get formattedSatisfaction() {
        return this.formatPercentage(this.metrics.customerSatisfaction);
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get pageInfo() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
        return `${start}-${end} of ${this.totalRecords}`;
    }
}