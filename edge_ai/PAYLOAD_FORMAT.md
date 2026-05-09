# MQTT Payload Format

## 📡 Input: Telemetry Data

**Topic**: `battlefield/sensor`

### Complete Example

```json
{
  "tick": 42,
  "timestamp": 1778280852338,
  "squad": [
    {
      "id": "alpha",
      "callsign": "ALPHA-1",
      "status": "nominal",
      "heartRate": 82,
      "battery": 91,
      "lat": 12.9795,
      "lng": 77.5924
    },
    {
      "id": "bravo",
      "callsign": "BRAVO-2",
      "status": "warning",
      "heartRate": 108,
      "battery": 54,
      "lat": 12.9793,
      "lng": 77.5921
    }
  ],
  "enemy": {
    "callsign": "HOSTILE",
    "lat": 12.9797,
    "lng": 77.5930
  },
  "hostage": {
    "callsign": "HOSTAGE",
    "lat": 12.9796,
    "lng": 77.5928
  }
}
```

### Field Descriptions

#### Root Level
- **`tick`** (integer, required): Sequence number for this telemetry update
- **`timestamp`** (integer, required): Unix timestamp in milliseconds
- **`squad`** (array, required): Array of squad member objects (minimum 1)
- **`enemy`** (object, required): Enemy position and info
- **`hostage`** (object, required): Hostage position and info

#### Squad Member Object
- **`id`** (string, required): Unique identifier (e.g., "alpha", "bravo")
- **`callsign`** (string, required): Radio callsign (e.g., "ALPHA-1")
- **`status`** (string, required): Member status
  - `"nominal"` - Normal operation
  - `"warning"` - Caution required
  - `"critical"` - Immediate attention needed
- **`heartRate`** (integer, required): Heart rate in beats per minute
- **`battery`** (integer, required): Battery percentage (0-100)
- **`lat`** (float, required): Latitude (GPS coordinate)
- **`lng`** (float, required): Longitude (GPS coordinate)

#### Enemy Object
- **`callsign`** (string, required): Enemy identifier
- **`lat`** (float, required): Latitude (GPS coordinate)
- **`lng`** (float, required): Longitude (GPS coordinate)

#### Hostage Object
- **`callsign`** (string, required): Hostage identifier
- **`lat`** (float, required): Latitude (GPS coordinate)
- **`lng`** (float, required): Longitude (GPS coordinate)

---

## 📤 Output: AI Response

**Topic**: `battlefield/ai-response`

### Example

```json
{
  "decision": "Take cover and assess situation",
  "risk_score": 0.87,
  "timestamp": 1778280852338,
  "latency_ms": 2450
}
```

### Field Descriptions

- **`decision`** (string): Tactical recommendation from AI
- **`risk_score`** (float): Normalized risk score (0.0 to 1.0)
- **`timestamp`** (integer): Original telemetry timestamp (echoed back)
- **`latency_ms`** (integer): Processing time in milliseconds

---

## 🧪 Test Commands

### Subscribe to Responses
```bash
mosquitto_sub -t "battlefield/ai-response" -v
```

### Send Test Telemetry
```bash
mosquitto_pub -t "battlefield/sensor" -m '{
  "tick": 42,
  "timestamp": 1778280852338,
  "squad": [
    {
      "id": "alpha",
      "callsign": "ALPHA-1",
      "status": "nominal",
      "heartRate": 82,
      "battery": 91,
      "lat": 12.9795,
      "lng": 77.5924
    },
    {
      "id": "bravo",
      "callsign": "BRAVO-2",
      "status": "warning",
      "heartRate": 108,
      "battery": 54,
      "lat": 12.9793,
      "lng": 77.5921
    }
  ],
  "enemy": {
    "callsign": "HOSTILE",
    "lat": 12.9797,
    "lng": 77.5930
  },
  "hostage": {
    "callsign": "HOSTAGE",
    "lat": 12.9796,
    "lng": 77.5928
  }
}'
```

---

## 📊 How It Works

1. **Telemetry Reception**: System receives squad telemetry via MQTT
2. **Primary Soldier Selection**: Identifies highest-risk soldier (highest heart rate)
3. **Distance Calculation**: Uses Haversine formula to calculate GPS distances
4. **Threat Analysis**: 
   - Enemy distance from primary soldier
   - Squad status (nominal/warning/critical)
   - Hostage proximity to enemy
   - Soldier stress levels (heart rate)
5. **Risk Scoring**: Weighted formula considering:
   - Distance factor (50%)
   - Stress factor (20%)
   - Hostage factor (15%)
   - Squad status factor (15%)
6. **AI Decision**: LLM generates tactical recommendation
7. **Response Publishing**: Decision sent back via MQTT

---

## 🎯 Key Features

- ✅ **Multi-soldier support**: Handles squads of any size
- ✅ **GPS coordinates**: Real-world latitude/longitude
- ✅ **Squad status tracking**: Individual member status monitoring
- ✅ **Battery monitoring**: Track equipment power levels
- ✅ **Automatic primary selection**: Identifies highest-risk soldier
- ✅ **Haversine distance**: Accurate GPS-based distance calculation

---

## 📝 Notes

- All GPS coordinates use decimal degrees format
- Distances are calculated in meters using Haversine formula
- Heart rate thresholds: >120 bpm = HIGH stress
- Distance thresholds: <100m = CRITICAL threat
- Squad status: Any "critical" member = CRITICAL squad status
- Primary soldier: Member with highest heart rate (most stressed)
