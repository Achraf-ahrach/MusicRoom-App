#!/bin/bash

# MusicRoom Delegation Test Script
# This script tests the complete flow: Users -> Playlist -> Delegation

echo "=========================================="
echo "MusicRoom Delegation Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8080"

# ========== STEP 1: Create User Alice ==========
echo -e "${YELLOW}[1/10] Creating User Alice (Owner)...${NC}"
ALICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "password123",
    "displayname": "Alice Owner"
  }')

ALICE_ID=$(echo "$ALICE_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Alice Created${NC}"
echo "  Alice ID: $ALICE_ID"
echo ""

# ========== STEP 2: Create User Bob ==========
echo -e "${YELLOW}[2/10] Creating User Bob (Delegate)...${NC}"
BOB_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "bob@example.com",
    "password": "password123",
    "displayname": "Bob Delegate"
  }')

BOB_ID=$(echo "$BOB_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Bob Created${NC}"
echo "  Bob ID: $BOB_ID"
echo ""

# ========== STEP 3: Create Playlist ==========
echo -e "${YELLOW}[3/10] Creating Playlist (Alice)...${NC}"
PLAYLIST_RESPONSE=$(curl -s -X POST "$BASE_URL/api/playlists" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-token" \
  -d '{
    "name": "My Summer Playlist",
    "description": "Summer hits 2026",
    "visibility": "public",
    "licenseType": "open"
  }')

PLAYLIST_ID=$(echo "$PLAYLIST_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Playlist Created${NC}"
echo "  Playlist ID: $PLAYLIST_ID"
echo ""

# ========== STEP 4: Grant Delegation ==========
echo -e "${YELLOW}[4/10] Granting Delegation (Alice -> Bob) FULL Access...${NC}"
DELEGATION_RESPONSE=$(curl -s -X POST "$BASE_URL/api/delegations/add-delegation" \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerId\": \"$ALICE_ID\",
    \"delegateId\": \"$BOB_ID\",
    \"resourceId\": \"$PLAYLIST_ID\",
    \"resourceType\": \"PLAYLIST\",
    \"permissionLevel\": \"FULL\",
    \"expiresAt\": \"2026-12-31T23:59:59\"
  }")

DELEGATION_ID=$(echo "$DELEGATION_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Delegation Created${NC}"
echo "  Delegation ID: $DELEGATION_ID"
echo ""

# ========== STEP 5: Check Access ==========
echo -e "${YELLOW}[5/10] Checking if Bob has Access...${NC}"
ACCESS_RESPONSE=$(curl -s -X POST "$BASE_URL/api/delegations/check-access" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$BOB_ID\",
    \"resourceId\": \"$PLAYLIST_ID\",
    \"resourceType\": \"PLAYLIST\"
  }")

HAS_ACCESS=$(echo "$ACCESS_RESPONSE" | grep -o '"hasAccess":[^,}]*' | cut -d':' -f2)
if [ "$HAS_ACCESS" = "true" ]; then
  echo -e "${GREEN}✓ Bob HAS ACCESS to Playlist${NC}"
else
  echo -e "${RED}✗ Bob DOES NOT HAVE ACCESS${NC}"
fi
echo ""

# ========== STEP 6: Get All Delegations for Playlist ==========
echo -e "${YELLOW}[6/10] Getting All Delegations for Playlist...${NC}"
DELEGATIONS=$(curl -s -X GET "$BASE_URL/api/delegations/resource/$PLAYLIST_ID?type=PLAYLIST")
DELEGATION_COUNT=$(echo "$DELEGATIONS" | grep -o '"id":"[^"]*"' | wc -l)
echo -e "${GREEN}✓ Retrieved Delegations${NC}"
echo "  Total Delegations: $DELEGATION_COUNT"
echo ""

# ========== STEP 7: Get Bob's Delegations ==========
echo -e "${YELLOW}[7/10] Getting Bob's Delegations...${NC}"
BOB_DELEGATIONS=$(curl -s -X GET "$BASE_URL/api/delegations/user/$BOB_ID")
BOB_DELEGATION_COUNT=$(echo "$BOB_DELEGATIONS" | grep -o '"id":"[^"]*"' | wc -l)
echo -e "${GREEN}✓ Retrieved Bob's Delegations${NC}"
echo "  Bob's Delegations: $BOB_DELEGATION_COUNT"
echo ""

# ========== STEP 8: Update Permission ==========
echo -e "${YELLOW}[8/10] Updating Permission (FULL -> PLAY_PAUSE)...${NC}"
UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/delegations/$DELEGATION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerId\": \"$ALICE_ID\",
    \"permissionLevel\": \"PLAY_PAUSE\",
    \"active\": true
  }")

UPDATED_PERMISSION=$(echo "$UPDATE_RESPONSE" | grep -o '"permissionLevel":"[^"]*"' | cut -d'"' -f4)
echo -e "${GREEN}✓ Permission Updated${NC}"
echo "  New Permission: $UPDATED_PERMISSION"
echo ""

# ========== STEP 9: Revoke Delegation ==========
echo -e "${YELLOW}[9/10] Revoking Delegation...${NC}"
DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/delegations/$DELEGATION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerId\": \"$ALICE_ID\"
  }")
HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "204" ]; then
  echo -e "${GREEN}✓ Delegation Revoked (HTTP 204)${NC}"
else
  echo -e "${RED}✗ Failed to Revoke (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# ========== STEP 10: Verify Bob Lost Access ==========
echo -e "${YELLOW}[10/10] Verifying Bob Lost Access...${NC}"
FINAL_ACCESS=$(curl -s -X POST "$BASE_URL/api/delegations/check-access" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$BOB_ID\",
    \"resourceId\": \"$PLAYLIST_ID\",
    \"resourceType\": \"PLAYLIST\"
  }")
HAS_ACCESS=$(echo "$FINAL_ACCESS" | grep -o '"hasAccess":[^,}]*' | cut -d':' -f2)

if [ "$HAS_ACCESS" = "false" ]; then
  echo -e "${GREEN}✓ Bob NO LONGER HAS ACCESS${NC}"
else
  echo -e "${RED}✗ Bob Still Has Access (Expected: false, Got: $HAS_ACCESS)${NC}"
fi
echo ""

# ========== Summary ==========
echo "=========================================="
echo -e "${GREEN}✓ Test Suite Complete!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  Alice ID: $ALICE_ID"
echo "  Bob ID: $BOB_ID"
echo "  Playlist ID: $PLAYLIST_ID"
echo "  Delegation ID: $DELEGATION_ID"
echo ""
