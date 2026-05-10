const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api';

const USERS_COUNT = 10;
const PASS = 'Password123!';

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function seed() {
    console.log('Starting seed process...');
    
    const createdUsers = [];

    // 1. Create Users
    for (let i = 1; i <= USERS_COUNT; i++) {
        const email = `a${i}@a.a`;
        const displayname = `Dummy User ${i}`;
        
        try {
            console.log(`Registering user: ${email}...`);
            await axios.post(`${BASE_URL}/auth/register`, {
                email,
                password: PASS,
                displayname
            });
        } catch (e) {
            if (e.response && e.response.status === 400) {
                console.log(`User ${email} might already exist. Trying to proceed...`);
            } else {
                console.error(`Error registering ${email}:`, e.response ? e.response.data : e.message);
            }
        }

        // Login to get token
        let token = null;
        try {
            const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
                email,
                password: PASS
            });
            token = loginRes.data.accessToken;
            createdUsers.push({ email, displayname, token });
        } catch (e) {
            console.error(`Error logging in ${email}:`, e.message);
        }
    }

    if (createdUsers.length === 0) {
        console.error("No users were created or logged in. Aborting.");
        return;
    }

    // 2. Search for Anas and make everyone follow him & add Playlists (Events)
    for (const user of createdUsers) {
        let headers = { Authorization: `Bearer ${user.token}` };

        // Search Anas
        try {
            console.log(`[${user.email}] Searching for Anas Bouzanbil...`);
            const searchRes = await axios.get(`${BASE_URL}/friendships/search?name=Anas Bouzanbil`, { headers });
            
            if (searchRes.data && searchRes.data.length > 0) {
                const anasId = searchRes.data[0].id;
                console.log(`[${user.email}] Found Anas (ID: ${anasId}). Sending friend request...`);
                
                await axios.post(`${BASE_URL}/friendships/request`, {
                    addresseeId: anasId
                }, { headers });
            } else {
                console.log(`[${user.email}] Anas not found. Skipping follow Anas.`);
            }
        } catch (e) {
            console.error(`[${user.email}] Error searching/following Anas:`, e.response ? e.response.data : e.message);
        }

        // Playlists (Events)
        try {
            console.log(`[${user.email}] Creating dummy playlists (Events) and inviting Anas...`);
            let defaultAnasId = null;
            
            // Re-search Anas just to have ID here if we didn't save it outside
            const sRes = await axios.get(`${BASE_URL}/friendships/search?name=Anas Bouzanbil`, { headers });
            if (sRes.data && sRes.data.length > 0) defaultAnasId = sRes.data[0].id;

            for (let p = 1; p <= 3; p++) {
                const eventRes = await axios.post(`${BASE_URL}/events`, {
                    name: `Playlist ${p} by ${user.displayname}`,
                    description: `This is dummy playlist ${p}`,
                    visibility: "public",
                    licenseType: "open",
                    latitude: 48.8566,
                    longitude: 2.3522,
                    startsAt: new Date(Date.now() + 86400000).toISOString(),
                    endsAt: new Date(Date.now() + 172800000).toISOString()
                }, { headers });
                
                // Invite Anas to this playlist if found
                if (defaultAnasId && eventRes.data && eventRes.data.id) {
                    await axios.post(`${BASE_URL}/events/${eventRes.data.id}/invite`, {
                        userId: defaultAnasId,
                        role: "GUEST"
                    }, { headers });
                }
            }
        } catch (e) {
             console.error(`[${user.email}] Error creating playlists:`, e.response ? e.response.data : e.message);
        }
    }

    // 3. Follow each other
    for (let i = 0; i < createdUsers.length; i++) {
        let headers = { Authorization: `Bearer ${createdUsers[i].token}` };
        
        // Let's have each user send request to the next 3 users
        for (let j = i + 1; j <= i + 3 && j < createdUsers.length; j++) {
            try {
                // To send a request, we need target ID. Wait, we don't have their IDs! 
                // We must search them first by exact displayname.
                const searchRes = await axios.get(`${BASE_URL}/friendships/search?name=${encodeURIComponent(createdUsers[j].displayname)}`, { headers });
                if (searchRes.data && searchRes.data.length > 0) {
                    const targetId = searchRes.data[0].id;
                    console.log(`[${createdUsers[i].email}] Sending friend request to ${createdUsers[j].email}...`);
                    await axios.post(`${BASE_URL}/friendships/request`, {
                        addresseeId: targetId
                    }, { headers });
                }
            } catch (e) {
                console.error(`[${createdUsers[i].email}] Error following ${createdUsers[j].email}:`, e.message);
            }
        }
    }

    console.log('Seed process finished!');
}

seed().catch(err => {
    console.error('Fatal seed error:', err);
});
