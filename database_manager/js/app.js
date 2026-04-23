// Application Controller
const App = {
    state: {
        currentView: 'dashboard', // households -> dashboard, residents -> peoples, statistics -> stat
        currentPage: 1,
        pageSize: 100,
        totalItems: 0,
        query: '',
        data: [],
        editingId: null,
        locations: {
            districts: [],
            neighborhoods: [],
            streets: []
        }
    },

    async init() {
        this.setupEventListeners();
        this.handleRouting();
        this.loadLocations(); // Background load locations
    },

    handleRouting() {
        const hash = window.location.hash || '#/dashboard';
        const routes = {
            '#/dashboard': 'households',
            '#/peoples': 'residents',
            '#/stat': 'statistics'
        };
        
        const view = routes[hash] || 'households';
        this.state.currentView = view;
        
        // Update active nav item
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.getAttribute('href') === hash);
        });
        
        this.state.currentPage = 1;
        this.loadData();
    },

    async loadLocations() {
        try {
            this.state.locations.districts = await Repository.getDistricts();
        } catch (error) {
            console.error('Locations load error:', error);
        }
    },

    setupEventListeners() {
        // Hash Change Listener
        window.addEventListener('hashchange', () => this.handleRouting());

        // Search
        document.getElementById('global-search').addEventListener('input', (e) => {
            this.state.query = e.target.value;
            this.state.currentPage = 1;
            // Debounce search
            clearTimeout(this.searchTimeout);
            this.searchTimeout = setTimeout(() => this.loadData(), 500);
        });

        // Refresh
        document.getElementById('refresh-btn').addEventListener('click', () => this.loadData());

        // Modal Close
        document.querySelectorAll('.close-modal').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.modal').forEach(m => m.style.display = 'none');
            });
        });

        // Form Submit
        UI.editForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(UI.editForm);
            const table = formData.get('type');
            const data = Object.fromEntries(formData.entries());
            delete data.type;
            
            try {
                await Repository.update(table, this.state.editingId, data);
                UI.editModal.style.display = 'none';
                await this.loadData();
                alert('Muvaffaqiyatli saqlandi!');
            } catch (error) {
                console.error(error);
                alert('Xatolik yuz berdi');
            }
        });

        // Dynamic dropdown listeners
        document.addEventListener('change', async (e) => {
            if (e.target.name === 'tuman_name') {
                const district = this.state.locations.districts.find(d => d.name === e.target.value);
                if (district) {
                    const mfyDropdown = document.querySelector('select[name="mfy_name"]');
                    mfyDropdown.innerHTML = '<option value="">Yuklanmoqda...</option>';
                    const neighborhoods = await Repository.getNeighborhoods(district.id);
                    mfyDropdown.innerHTML = '<option value="">Tanlang...</option>' + 
                        neighborhoods.map(n => `<option value="${n.name}" data-id="${n.id}">${n.name}</option>`).join('');
                }
                this.updateAddressPreview();
            } else if (e.target.name === 'mfy_name') {
                const selectedOption = e.target.options[e.target.selectedIndex];
                const neighborhoodId = selectedOption.dataset.id;
                if (neighborhoodId) {
                    const streetDropdown = document.querySelector('select[name="street_name"]');
                    streetDropdown.innerHTML = '<option value="">Yuklanmoqda...</option>';
                    const streets = await Repository.getStreets(neighborhoodId);
                    streetDropdown.innerHTML = '<option value="">Tanlang...</option>' + 
                        streets.map(s => `<option value="${s.name}">${s.name}</option>`).join('');
                }
                this.updateAddressPreview();
            } else if (e.target.name === 'street_name' || e.target.name === 'house_number') {
                this.updateAddressPreview();
            }
        });

        // House number input listener
        document.addEventListener('input', (e) => {
            if (e.target.name === 'house_number') {
                this.updateAddressPreview();
            }
        });
    },

    updateAddressPreview() {
        const tuman = document.querySelector('select[name="tuman_name"]')?.value || '';
        const mfy = document.querySelector('select[name="mfy_name"]')?.value || '';
        const street = document.querySelector('select[name="street_name"]')?.value || '';
        const house = document.querySelector('input[name="house_number"]')?.value || '';
        
        const previewInput = document.querySelector('input[name="official_address"]');
        if (previewInput) {
            let full = "Farg'ona viloyati";
            if (tuman) full += `, ${tuman}`;
            if (mfy) full += `, ${mfy}`;
            if (street) full += `, ${street}`;
            if (house) full += `, ${house}-uy`;
            previewInput.value = full;
        }
    },

    async loadData() {
        const icon = document.querySelector('#refresh-btn i');
        if (icon) icon.classList.add('fa-spin');

        try {
            let result;
            if (this.state.currentView === 'households') {
                result = await Repository.getHouseholds(this.state.currentPage, this.state.pageSize, this.state.query);
                UI.renderHouseholds(result.data);
            } else if (this.state.currentView === 'residents') {
                result = await Repository.getResidents(this.state.currentPage, this.state.pageSize, this.state.query);
                UI.renderResidents(result.data);
            } else if (this.state.currentView === 'statistics') {
                const stats = await Repository.getStats();
                UI.renderStatistics(stats);
                return;
            }

            this.state.data = result.data;
            this.state.totalItems = result.count;
            UI.dataCountBadge.innerText = `${result.count} ta yozuv`;
            
            const totalPages = Math.ceil(result.count / this.state.pageSize);
            UI.renderPagination(this.state.currentPage, totalPages);

        } catch (error) {
            console.error(error);
        } finally {
            if (icon) icon.classList.remove('fa-spin');
        }
    },

    setPage(page) {
        this.state.currentPage = page;
        this.loadData();
    },

    async deleteData(table, id) {
        if (!confirm('Rostdan ham o\'chirmoqchimisiz?')) return;
        try {
            await Repository.delete(table, id);
            await this.loadData();
        } catch (error) {
            console.error(error);
            alert('O\'chirishda xatolik');
        }
    },

    showDetails(type, id) {
        const item = this.state.data.find(d => d.id === id);
        if (item) UI.showDetailsModal(type, item);
    },

    async openEditModal(type, id) {
        this.state.editingId = id;
        const item = this.state.data.find(d => d.id === id);
        if (!item) return;

        UI.formFields.innerHTML = '<div style="text-align: center; padding: 20px;"><i class="fas fa-spinner fa-spin"></i> Yuklanmoqda...</div>';
        UI.editModal.style.display = 'flex';

        if (type === 'household') {
            const district = this.state.locations.districts.find(d => d.name === item.tuman_name);
            let neighborhoods = [];
            let streets = [];

            if (district) {
                neighborhoods = await Repository.getNeighborhoods(district.id);
                const neighborhood = neighborhoods.find(n => n.name === item.mfy_name);
                if (neighborhood) {
                    streets = await Repository.getStreets(neighborhood.id);
                }
            }

            const districtHtml = this.state.locations.districts.map(d => 
                `<option value="${d.name}" ${item.tuman_name === d.name ? 'selected' : ''} data-id="${d.id}">${d.name}</option>`
            ).join('');

            const mfyHtml = neighborhoods.map(n => 
                `<option value="${n.name}" ${item.mfy_name === n.name ? 'selected' : ''} data-id="${n.id}">${n.name}</option>`
            ).join('');

            const streetHtml = streets.map(s => 
                `<option value="${s.name}" ${item.street_name === s.name ? 'selected' : ''}>${s.name}</option>`
            ).join('');

            UI.formFields.innerHTML = `
                <input type="hidden" name="type" value="households">
                <div class="form-group">
                    <label>Tuman / Shahar</label>
                    <select name="tuman_name" required>
                        <option value="">Tanlang...</option>
                        ${districtHtml}
                    </select>
                </div>
                <div class="form-group">
                    <label>MFY (Mahalla)</label>
                    <select name="mfy_name" required>
                        <option value="">Tanlang...</option>
                        ${mfyHtml}
                    </select>
                </div>
                <div class="form-group">
                    <label>Ko'cha</label>
                    <select name="street_name">
                        <option value="">Tanlang...</option>
                        ${streetHtml}
                    </select>
                </div>
                <div class="form-group">
                    <label>Uy raqami / Kvartira</label>
                    <input type="text" name="house_number" value="${item.house_number || ''}">
                </div>
                <div class="form-group">
                    <label>Rasmiy to'liq manzil (Preview)</label>
                    <input type="text" name="official_address" value="${item.official_address}" readonly style="background: #f8f9fa; color: #6c757d; cursor: not-allowed;">
                </div>
            `;
        } else {
            UI.formFields.innerHTML = `
                <input type="hidden" name="type" value="residents">
                <div class="form-group">
                    <label>Ism</label>
                    <input type="text" name="first_name" value="${item.first_name}" required>
                </div>
                <div class="form-group">
                    <label>Familiya</label>
                    <input type="text" name="last_name" value="${item.last_name}" required>
                </div>
                <div class="form-group">
                    <label>Telefon</label>
                    <input type="text" name="phone_primary" value="${item.phone_primary || ''}">
                </div>
            `;
        }
    }
};

// Start App
document.addEventListener('DOMContentLoaded', () => App.init());
