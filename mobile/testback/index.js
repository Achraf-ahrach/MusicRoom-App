const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const DATA_FILE = path.join(__dirname, 'users.json');

// Initialize data file if it doesn't exist
if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([]));
}

const readUsers = () => {
    const data = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(data || '[]');
};

const writeUsers = (users) => {
    fs.writeFileSync(DATA_FILE, JSON.stringify(users, null, 2));
};

// POST /signup
app.post('/signup', (req, res) => {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
        return res.status(400).json({ error: 'Missing full name, email, or password' });
    }

    const users = readUsers();
    if (users.find(u => u.email === email)) {
        return res.status(400).json({ error: 'User already exists' });
    }

    const token = Math.floor(100000 + Math.random() * 900000).toString();
    console.log('====================================');
    console.log(`[SIGNUP] OTP generated for ${email}: ${token}`);
    console.log('====================================');
    const newUser = {
        id: Date.now().toString(),
        fullName,
        email,
        password, // Testing only: storing plain text
        token,
        isVerified: false
    };

    users.push(newUser);
    writeUsers(users);

    res.json({ message: 'User created successfully', token });
});

// POST /login
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const users = readUsers();

    const user = users.find(u => u.email === email && u.password === password);
    if (!user) {
        return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (!user.isVerified) {
        return res.status(401).json({ error: 'User is not verified' });
    }

    const accessToken = crypto.randomBytes(32).toString('hex');
    const refreshToken = crypto.randomBytes(32).toString('hex');

    const userIndex = users.findIndex(u => u.id === user.id);
    users[userIndex].accessToken = accessToken;
    users[userIndex].refreshToken = refreshToken;
    writeUsers(users);

    // Login successful
    res.json({ 
        message: 'Login successful', 
        user: { id: user.id, fullName: user.fullName, email: user.email },
        accessToken,
        refreshToken
    });
});

// POST /resend-otp
app.post('/resend-otp', (req, res) => {
    const { email } = req.body;
    const users = readUsers();

    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    if (users[userIndex].isVerified) {
        return res.status(400).json({ error: 'User is already verified' });
    }

    const token = Math.floor(100000 + Math.random() * 900000).toString();
    users[userIndex].token = token;
    writeUsers(users);

    console.log('====================================');
    console.log(`[RESEND] New OTP generated for ${email}: ${token}`);
    console.log('====================================');

    res.json({ message: 'OTP resent successfully' });
});

// POST /verify-otp
app.post('/verify-otp', (req, res) => {
    const { email, token } = req.body;
    const users = readUsers();

    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    if (users[userIndex].token !== token) {
        return res.status(400).json({ error: 'Invalid token' });
    }

    const accessToken = crypto.randomBytes(32).toString('hex');
    const refreshToken = crypto.randomBytes(32).toString('hex');

    // Verify and remove token, add access/refresh tokens
    users[userIndex].isVerified = true;
    users[userIndex].token = null;
    users[userIndex].accessToken = accessToken;
    users[userIndex].refreshToken = refreshToken;
    writeUsers(users);

    res.json({ 
        message: 'User verified successfully',
        user: { id: users[userIndex].id, fullName: users[userIndex].fullName, email: users[userIndex].email },
        accessToken,
        refreshToken
    });
});

// POST /forgot-password
app.post('/forgot-password', (req, res) => {
    const { email } = req.body;
    const users = readUsers();

    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
        // To prevent user enumeration, we shouldn't fail explicitly, but for testing it's fine.
        return res.status(404).json({ error: 'User not found' });
    }

    const token = Math.floor(100000 + Math.random() * 900000).toString();
    users[userIndex].token = token;
    writeUsers(users);

    console.log('====================================');
    console.log(`[FORGOT PASSWORD] OTP generated for ${email}: ${token}`);
    console.log('====================================');

    res.json({ message: 'OTP sent to email' });
});

// POST /verify-reset-otp
app.post('/verify-reset-otp', (req, res) => {
    const { email, token } = req.body;
    const users = readUsers();

    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    if (users[userIndex].token !== token) {
        return res.status(400).json({ error: 'Invalid token' });
    }

    res.json({ message: 'Token verified successfully' });
});

// POST /reset-password
app.post('/reset-password', (req, res) => {
    const { email, token, newPassword } = req.body;
    const users = readUsers();

    const userIndex = users.findIndex(u => u.email === email);
    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    if (users[userIndex].token !== token) {
        return res.status(400).json({ error: 'Invalid token' });
    }

    const accessToken = crypto.randomBytes(32).toString('hex');
    const refreshToken = crypto.randomBytes(32).toString('hex');

    // Update password, clear token, set tokens
    users[userIndex].password = newPassword;
    users[userIndex].token = null;
    users[userIndex].accessToken = accessToken;
    users[userIndex].refreshToken = refreshToken;
    writeUsers(users);

    res.json({ 
        message: 'Password reset successfully',
        user: { id: users[userIndex].id, fullName: users[userIndex].fullName, email: users[userIndex].email },
        accessToken,
        refreshToken
    });
});

// POST /auth/google (Mock for Google OAuth)
app.post('/auth/google', (req, res) => {
    const { email, fullName, googleId } = req.body;
    if (!email) {
        return res.status(400).json({ error: 'Email is required from Google Auth' });
    }

    const users = readUsers();
    let user = users.find(u => u.email === email);

    if (!user) {
        // Auto-create and verify — Google users skip the OTP flow
        user = {
            id: googleId || Date.now().toString(),
            fullName: fullName || 'Google User',
            email,
            password: null,
            token: null,
            isVerified: true
        };
        users.push(user);
    } else if (!user.isVerified) {
        user.isVerified = true;
        user.token = null;
    }

    // Generate session tokens (same as login/verify endpoints)
    const accessToken = crypto.randomBytes(32).toString('hex');
    const refreshToken = crypto.randomBytes(32).toString('hex');

    const userIndex = users.findIndex(u => u.email === email);
    users[userIndex].accessToken = accessToken;
    users[userIndex].refreshToken = refreshToken;
    writeUsers(users);

    console.log('====================================');
    console.log(`[GOOGLE AUTH] Login successful for ${email}`);
    console.log('====================================');

    res.json({ 
        message: 'Google login successful',
        user: { id: user.id, fullName: user.fullName, email: user.email },
        accessToken,
        refreshToken
    });
});

// Mock Google Auth endpoint for testing
app.post('/api/auth/google', (req, res) => {
    const { token } = req.body;
    
    if (!token) {
        return res.status(400).json({ error: 'Token is required' });
    }

    // Mock successful authentication
    res.json({
        success: true,
        user: {
            id: '12345',
            name: 'Spotify User',
            email: 'user@example.com'
        },
        sessionToken: 'mock_session_token_xyz'
    });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
