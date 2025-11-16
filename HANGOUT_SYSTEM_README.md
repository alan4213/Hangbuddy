# Real-time Hangout Request System

## Overview
The HangBuddy app now features a real-time hangout request sharing system that allows users to create and discover hangout opportunities instantly across all devices.

## How It Works

### 1. Database Structure
- **Collection**: `hangout_requests` in Firestore
- **Fields**:
  - `id`: Unique request identifier
  - `creatorId`: User ID who created the request
  - `title`: Hangout title/activity
  - `description`: Detailed description
  - `dateTime`: When the hangout will happen
  - `location`: Where it will take place
  - `maxParticipants`: Maximum number of people
  - `status`: Request status (active/completed/cancelled)
  - `createdAt`: Creation timestamp
  - `interestedUsers`: Array of user IDs who expressed interest

### 2. Real-time Flow
1. **User A creates hangout** → Saved to Firestore `hangout_requests` collection
2. **Firestore triggers update** → All connected clients receive the change
3. **User B's home screen** → Automatically updates via StreamBuilder
4. **User B sees new request** → Appears instantly without refresh

### 3. Key Components

#### Models
- `HangoutRequest`: Data structure for hangout requests
- `UserModel`: Existing user data structure

#### Services
- `HangoutService`: Handles all CRUD operations for hangout requests
  - `createHangoutRequest()`: Creates new requests
  - `getActiveHangoutRequests()`: Returns real-time stream of requests
  - `expressInterest()`: Adds user to interested list
  - `removeInterest()`: Removes user from interested list

#### Screens
- `CreateHangoutScreen`: Enhanced to save to Firestore
- `HomeScreen`: Updated with StreamBuilder for real-time updates

### 4. Real-time Features
- **Instant Updates**: New hangouts appear immediately on all devices
- **Live Interest Tracking**: See who's interested in real-time
- **Auto-sync**: No manual refresh needed
- **Offline Support**: Firestore handles offline caching automatically

### 5. Security
- Firestore security rules ensure:
  - Users can only create requests with their own ID
  - Only authenticated users can view active requests
  - Users can express/remove interest in others' requests
  - Creators can manage their own requests

### 6. Usage
1. **Create Hangout**: Fill form → Automatically appears on others' feeds
2. **Browse Hangouts**: Real-time feed updates as new requests are added
3. **Express Interest**: Tap green checkmark → Added to interested users list
4. **Pass on Hangout**: Tap red X → Request dismissed locally

## Technical Implementation

### StreamBuilder Integration
```dart
StreamBuilder<List<HangoutRequest>>(
  stream: HangoutService.getActiveHangoutRequests(),
  builder: (context, snapshot) {
    // Real-time UI updates
  },
)
```

### Firestore Query
```dart
_firestore
  .collection('hangout_requests')
  .where('status', isEqualTo: 'active')
  .where('creatorId', isNotEqualTo: currentUserId)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

This creates a live feed where hangout requests appear instantly across all users' devices without any manual intervention!