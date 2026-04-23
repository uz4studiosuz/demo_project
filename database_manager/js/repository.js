const Repository = {
    async getHouseholds(page = 1, pageSize = 10, query = '') {
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;

        let dbQuery = client
            .from('households')
            .select('*, residents(*)', { count: 'exact' })
            .eq('is_active', true);

        if (query) {
            dbQuery = dbQuery.or(`official_address.ilike.%${query}%,tuman_name.ilike.%${query}%,mfy_name.ilike.%${query}%`);
        }

        const { data, count, error } = await dbQuery
            .order('created_at', { ascending: false })
            .range(from, to);

        if (error) throw error;
        return { data, count };
    },

    async getResidents(page = 1, pageSize = 10, query = '') {
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;

        let dbQuery = client
            .from('residents')
            .select('*', { count: 'exact' })
            .eq('is_active', true);

        if (query) {
            dbQuery = dbQuery.or(`first_name.ilike.%${query}%,last_name.ilike.%${query}%,phone_primary.ilike.%${query}%`);
        }

        const { data, count, error } = await dbQuery
            .order('created_at', { ascending: false })
            .range(from, to);

        if (error) throw error;
        return { data, count };
    },

    async update(table, id, data) {
        const { error } = await client
            .from(table)
            .update(data)
            .eq('id', id);
        if (error) throw error;
    },

    async delete(table, id) {
        const { error } = await client
            .from(table)
            .update({ is_active: false })
            .eq('id', id);
        if (error) throw error;
    },

    // Location Data
    async getDistricts() {
        const { data, error } = await client.from('districts').select('*').order('name');
        if (error) throw error;
        return data;
    },

    async getNeighborhoods(districtId = null) {
        let dbQuery = client.from('neighborhoods').select('*').order('name');
        if (districtId) dbQuery = dbQuery.eq('district_id', districtId);
        const { data, error } = await dbQuery;
        if (error) throw error;
        return data;
    },

    async getStreets(neighborhoodId = null) {
        let dbQuery = client.from('streets').select('*').order('name');
        if (neighborhoodId) dbQuery = dbQuery.eq('neighborhood_id', neighborhoodId);
        const { data, error } = await dbQuery;
        if (error) throw error;
        return data;
    },

    async getStats() {
        const { count: hhCount } = await client.from('households').select('*', { count: 'exact', head: true }).eq('is_active', true);
        const { count: resCount } = await client.from('residents').select('*', { count: 'exact', head: true }).eq('is_active', true);
        
        // Property Type Distribution
        const { data: propData } = await client.from('households').select('property_type').eq('is_active', true);
        const propStats = propData.reduce((acc, curr) => {
            acc[curr.property_type] = (acc[curr.property_type] || 0) + 1;
            return acc;
        }, {});

        // Gender Distribution
        const { data: genData } = await client.from('residents').select('gender').eq('is_active', true);
        const genderStats = genData.reduce((acc, curr) => {
            acc[curr.gender] = (acc[curr.gender] || 0) + 1;
            return acc;
        }, {});

        // Top 5 MFYs
        const { data: mfyData } = await client.from('households').select('mfy_name').eq('is_active', true);
        const mfyStats = mfyData.reduce((acc, curr) => {
            if(curr.mfy_name) acc[curr.mfy_name] = (acc[curr.mfy_name] || 0) + 1;
            return acc;
        }, {});
        const sortedMfy = Object.entries(mfyStats).sort((a, b) => b[1] - a[1]).slice(0, 5);

        return {
            households: hhCount,
            residents: resCount,
            property: propStats,
            gender: genderStats,
            topMfy: sortedMfy
        };
    }
};
