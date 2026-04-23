const UI = {
    // Elements
    tableHead: document.getElementById('table-head'),
    tableBody: document.getElementById('table-body'),
    viewTitle: document.getElementById('view-title'),
    dataCountBadge: document.getElementById('data-count'),
    editModal: document.getElementById('edit-modal'),
    editForm: document.getElementById('edit-form'),
    formFields: document.getElementById('form-fields'),
    paginationContainer: document.getElementById('pagination-container'),

    renderHouseholds(households) {
        this.tableHead.innerHTML = `
            <tr>
                <th>ID</th>
                <th>Manzil</th>
                <th>Tuman/MFY</th>
                <th>Mulk turi</th>
                <th>Aholi</th>
                <th>Amallar</th>
            </tr>
        `;

        this.tableBody.innerHTML = households.map(h => `
            <tr>
                <td>#${h.id}</td>
                <td style="max-width: 250px;">${h.official_address}</td>
                <td>${h.tuman_name || '-'} / ${h.mfy_name || '-'}</td>
                <td><span class="badge" style="background: ${h.property_type === 'HOUSE' ? '#003366' : '#f39c12'}">${h.property_type === 'HOUSE' ? 'Hovli' : 'Kvartira'}</span></td>
                <td>${h.residents ? h.residents.length : 0} ta</td>
                <td>
                    <button class="btn-icon btn-view" onclick="App.showDetails('household', ${h.id})"><i class="fas fa-eye"></i></button>
                    <button class="btn-icon btn-edit" onclick="App.openEditModal('household', ${h.id})"><i class="fas fa-edit"></i></button>
                    <button class="btn-icon btn-delete" onclick="App.deleteData('households', ${h.id})"><i class="fas fa-trash-alt"></i></button>
                </td>
            </tr>
        `).join('');
    },

    renderResidents(residents) {
        this.tableHead.innerHTML = `
            <tr>
                <th>ID</th>
                <th>Ism Familiya</th>
                <th>Telefon</th>
                <th>Jinsi</th>
                <th>Amallar</th>
            </tr>
        `;

        this.tableBody.innerHTML = residents.map(r => `
            <tr>
                <td>#${r.id}</td>
                <td><strong>${r.last_name} ${r.first_name}</strong></td>
                <td>${r.phone_primary || '-'}</td>
                <td>${r.gender === 'MALE' ? 'Erkak' : 'Ayol'}</td>
                <td>
                    <button class="btn-icon btn-edit" onclick="App.openEditModal('resident', ${r.id})"><i class="fas fa-edit"></i></button>
                    <button class="btn-icon btn-delete" onclick="App.deleteData('residents', ${r.id})"><i class="fas fa-trash-alt"></i></button>
                </td>
            </tr>
        `).join('');
    },

    renderPagination(currentPage, totalPages) {
        if (totalPages <= 1) {
            this.paginationContainer.innerHTML = '';
            return;
        }

        let html = `
            <button class="btn-page" ${currentPage === 1 ? 'disabled' : ''} onclick="App.setPage(${currentPage - 1})"><i class="fas fa-chevron-left"></i></button>
            <span class="page-info">Sahifa ${currentPage} / ${totalPages}</span>
            <button class="btn-page" ${currentPage === totalPages ? 'disabled' : ''} onclick="App.setPage(${currentPage + 1})"><i class="fas fa-chevron-right"></i></button>
        `;
        this.paginationContainer.innerHTML = html;
    },

    showDetailsModal(type, data) {
        const detailsContainer = document.getElementById('details-content');
        let html = '';

        if (type === 'household') {
            html = `
                <div class="details-grid">
                    <div class="detail-item"><strong>ID:</strong> #${data.id}</div>
                    <div class="detail-item"><strong>Mulk turi:</strong> ${data.property_type === 'HOUSE' ? 'Hovli' : 'Kvartira'}</div>
                    <div class="detail-item"><strong>Tuman:</strong> ${data.tuman_name || 'Noma\'lum'}</div>
                    <div class="detail-item"><strong>MFY:</strong> ${data.mfy_name || 'Noma\'lum'}</div>
                    <div class="detail-item"><strong>Ko'cha:</strong> ${data.street_name || 'Noma\'lum'}</div>
                    <div class="detail-item"><strong>Manzil:</strong> ${data.officialAddress || data.official_address}</div>
                    <div class="detail-item">
                        <strong>Koordinata:</strong> ${data.latitude}, ${data.longitude}
                        <button class="btn-sm btn-primary" onclick="window.open('https://www.google.com/maps/search/?api=1&query=${data.latitude},${data.longitude}', '_blank')" style="margin-top: 5px; width: 100%;">
                            <i class="fas fa-map-marker-alt"></i> Google Maps'da ochish
                        </button>
                    </div>
                </div>
                <h4 style="margin-top: 20px;">Aholi ro'yxati (${data.residents ? data.residents.length : 0} nafar)</h4>
                <ul class="residents-mini-list">
                    ${data.residents ? data.residents.map(r => `<li>${r.last_name} ${r.first_name} - ${r.role || 'A\'zo'}</li>`).join('') : '<li>Ma\'lumot yo\'q</li>'}
                </ul>
            `;
        }

        detailsContainer.innerHTML = html;
        document.getElementById('details-modal').style.display = 'flex';
    },

    renderStatistics(stats) {
        this.viewTitle.innerText = "Tizim tahlili (Statistika)";
        this.tableHead.innerHTML = "";
        this.paginationContainer.innerHTML = "";
        this.dataCountBadge.innerText = "Real vaqt rejimi";

        this.tableBody.innerHTML = `
            <div class="stats-dashboard">
                <div class="stats-summary">
                    <div class="glass stats-card">
                        <i class="fas fa-house-user" style="color: #003366"></i>
                        <h3>${stats.households}</h3>
                        <p>Xonadonlar</p>
                    </div>
                    <div class="glass stats-card">
                        <i class="fas fa-users" style="color: #00b894"></i>
                        <h3>${stats.residents}</h3>
                        <p>Aholi soni</p>
                    </div>
                </div>
                <div class="stats-charts">
                    <div class="glass chart-container" style="height: 350px;">
                        <h4>Mulk turlari</h4>
                        <canvas id="propChart"></canvas>
                    </div>
                    <div class="glass chart-container" style="height: 350px;">
                        <h4>Jinsiy tarkib</h4>
                        <canvas id="genderChart"></canvas>
                    </div>
                    <div class="glass chart-container" style="grid-column: span 2; height: 400px;">
                        <h4>Eng ko'p xatlov o'tgan MFYlar (TOP 5)</h4>
                        <canvas id="mfyChart"></canvas>
                    </div>
                </div>
            </div>
        `;

        // Initialize Charts
        setTimeout(() => {
            new Chart(document.getElementById('propChart'), {
                type: 'pie',
                data: {
                    labels: ['Hovli', 'Kvartira'],
                    datasets: [{
                        data: [stats.property.HOUSE || 0, stats.property.APARTMENT || 0],
                        backgroundColor: ['#003366', '#f39c12']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });

            new Chart(document.getElementById('genderChart'), {
                type: 'doughnut',
                data: {
                    labels: ['Erkak', 'Ayol'],
                    datasets: [{
                        data: [stats.gender.MALE || 0, stats.gender.FEMALE || 0],
                        backgroundColor: ['#0984e3', '#e84393']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });

            new Chart(document.getElementById('mfyChart'), {
                type: 'bar',
                data: {
                    labels: stats.topMfy.map(m => m[0]),
                    datasets: [{
                        label: 'Xonadonlar soni',
                        data: stats.topMfy.map(m => m[1]),
                        backgroundColor: '#00b894'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } }
                }
            });
        }, 100);
    }
};
