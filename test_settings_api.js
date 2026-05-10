const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api';
const EMAIL = 'a1@a.a';
const PASS = 'Password123!';

async function testSettingsApi() {
    try {
        console.log(`Logging in as ${EMAIL}...`);
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: EMAIL,
            password: PASS
        });
        const token = loginRes.data.accessToken;
        
        const headers = { Authorization: `Bearer ${token}` };

        console.log('\n--- 1. Updating Profile (Settings) ---');
        const updateProfileRes = await axios.put(`${BASE_URL}/users/me`, {
            displayName: "Dummy User 1 (Updated)",
            avatarUrl: "https://example.com/avatar-updated.jpg",
            publicInfo: { "bio": "I love music and coding!" },
            privateInfo: { "phone": "+123456789" },
            friendsInfo: { "status": "Ready to jam!" }
        }, { headers });
        console.log('Profile Updated! Response:', updateProfileRes.data);

        console.log('\n--- 2. Updating Music Preferences ---');
        const updatePrefRes = await axios.put(`${BASE_URL}/users/me/preferences`, {
            musicPreferences: {
                "favorite_genres": ["rock", "electronic", "indie"],
                "discovery_mode": "active",
                "max_distance_km": 50
            }
        }, { headers });
        console.log('Preferences Updated! Response:', updatePrefRes.data);

        console.log('\n--- 3. Fetching Updated Profile ---');
        const getProfileRes = await axios.get(`${BASE_URL}/users/me`, { headers });
        console.log('My Profile State:', getProfileRes.data);

    } catch (e) {
        console.error('API Error:', e.response ? JSON.stringify(e.response.data, null, 2) : e.message);
    }
}

testSettingsApi();