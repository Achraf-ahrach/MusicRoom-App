const { Client } = require('pg');

function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

const USERS_COUNT = 10;
// We'll use the same hash for all test users so they have the exact same password if logged normally
const PASSWORD_HASH = '$2a$10$JnUmwvsZmPEuWk4OlHXxUunpAQR0WAYfrxqHIKBgsII0xYJRnhovS';

async function seed() {
    const client = new Client('postgresql://postgres:postgres@localhost:5432/musicroom');
    await client.connect();

    console.log('Connected to DB');

    try {
        // 1. Get Anas ID
        const anasRes = await client.query("SELECT id FROM users WHERE display_name = 'Anas Bouzanbil' LIMIT 1");
        if (anasRes.rows.length === 0) {
            console.error('Anas Bouzanbil not found in DB!');
            return;
        }
        const anasId = anasRes.rows[0].id;
        console.log(`Found Anas Bouzanbil with ID: ${anasId}`);

        // 2. Insert Users
        const createdUsers = [];
        for (let i = 1; i <= USERS_COUNT; i++) {
            const userId = uuidv4();
            const email = `a${i}@a.a`;
            const displayname = `Dummy User ${i}`;
            
            // Check if exists
            const existRes = await client.query("SELECT id FROM users WHERE email = $1", [email]);
            if (existRes.rows.length === 0) {
                await client.query(`
                    INSERT INTO users (id, email, display_name, password_hash, email_verified, auth_provider, created_at, updated_at) 
                    VALUES ($1, $2, $3, $4, true, 'LOCAL', NOW(), NOW())
                `, [userId, email, displayname, PASSWORD_HASH]);
                console.log(`Inserted user: ${email} (${userId})`);
                createdUsers.push({ id: userId, email, displayname });
            } else {
                console.log(`User ${email} already exists.`);
                createdUsers.push({ id: existRes.rows[0].id, email, displayname });
            }
        }

        // 3. Friendships
        // Make all created users friend with Anas
        for (const user of createdUsers) {
            // Check if already friends
            const friendRes = await client.query(`
                SELECT id FROM friendships 
                WHERE (requester_id = $1 AND addressee_id = $2) OR (requester_id = $2 AND addressee_id = $1)
            `, [user.id, anasId]);

            if (friendRes.rows.length === 0) {
                await client.query(`
                    INSERT INTO friendships (id, requester_id, addressee_id, status, created_at)
                    VALUES ($1, $2, $3, 'ACCEPTED', NOW())
                `, [uuidv4(), user.id, anasId]);
                console.log(`Created friendship between ${user.email} and Anas`);
            }
        }

        // Make mock users friend with each other (chain)
        for (let i = 0; i < createdUsers.length; i++) {
            for (let j = i + 1; j <= i + 3 && j < createdUsers.length; j++) {
                const u1 = createdUsers[i];
                const u2 = createdUsers[j];

                const friendRes = await client.query(`
                    SELECT id FROM friendships 
                    WHERE (requester_id = $1 AND addressee_id = $2) OR (requester_id = $2 AND addressee_id = $1)
                `, [u1.id, u2.id]);

                if (friendRes.rows.length === 0) {
                    await client.query(`
                        INSERT INTO friendships (id, requester_id, addressee_id, status, created_at)
                        VALUES ($1, $2, $3, 'ACCEPTED', NOW())
                    `, [uuidv4(), u1.id, u2.id]);
                }
            }
        }
        console.log('Created dummy friendships.');

        // 4. Events, Tracks, and Votes
        // Create some tracks first
        const mockTracks = [];
        for (let t = 1; t <= 20; t++) {
            const trackId = uuidv4();
            await client.query(`
                INSERT INTO tracks (id, external_id, provider, title, artist, album, cover_url, duration_ms, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
            `, [
                trackId, `ext-${t}`, 'spotify', `Hit Song ${t}`, `Artist ${t}`, `Album ${t}`, `http://example.com/cover${t}.jpg`, 180000 + (t * 1000)
            ]);
            mockTracks.push(trackId);
        }
        console.log('Created 20 mock tracks.');

        for (const user of createdUsers) {
            // Give them some generic preferences
            const pref = JSON.stringify({ genres: ["rock", "pop", "jazz"], discovery_mode: true });
            await client.query("UPDATE users SET music_preferences = $1 WHERE id = $2", [pref, user.id]);

            for (let p = 1; p <= 3; p++) {
                const eventId = uuidv4();
                
                await client.query(`
                    INSERT INTO events (id, name, description, visibility, license_type, owner_id, is_active, latitude, longitude, starts_at, ends_at, created_at)
                    VALUES ($1, $2, $3, 'public', 'open', $4, true, 48.8566, 2.3522, NOW() + INTERVAL '1 day', NOW() + INTERVAL '2 days', NOW())
                `, [eventId, `Playlist ${p} by ${user.displayname}`, `Dummy playlist ${p}`, user.id]);

                // Invite Anas
                await client.query(`
                    INSERT INTO event_invites (id, event_id, user_id, role, created_at)
                    VALUES ($1, $2, $3, 'GUEST', NOW())
                `, [uuidv4(), eventId, anasId]);

                // Add some tracks to this event_playlist
                for (let t = 0; t < 5; t++) {
                    const entryId = uuidv4();
                    const trackId = mockTracks[Math.floor(Math.random() * mockTracks.length)];
                    
                    await client.query(`
                        INSERT INTO event_playlist (id, event_id, track_id, suggested_by, vote_count, position, status, suggested_at)
                        VALUES ($1, $2, $3, $4, 1, $5, 'PENDING', NOW())
                    `, [entryId, eventId, trackId, user.id, t]);

                    // Add a default vote by Anas to make it active
                    await client.query(`
                        INSERT INTO votes (id, playlist_entry_id, user_id, value, voted_at)
                        VALUES ($1, $2, $3, 1, NOW())
                    `, [uuidv4(), entryId, anasId]);
                }
            }
            console.log(`Created events, added tracks, mapped preferences & votes for ${user.email}.`);
        }

        console.log('Database seeded successfully!');

    } catch (err) {
        console.error('Error seeding DB:', err);
    } finally {
        await client.end();
    }
}

seed();