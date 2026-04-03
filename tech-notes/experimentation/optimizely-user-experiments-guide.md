# How to Fetch All Experiments for a User Using Optimizely REST APIs

Optimizely offers multiple approaches for retrieving experiment and feature flag assignments for users. This comprehensive guide explores the different REST API methods, their tradeoffs, and provides practical code samples to help you choose the best approach for your use case.

## Table of Contents
- [Overview of Available APIs](#overview-of-available-apis)
- [Method 1: Agent API Decide Endpoint (Recommended)](#method-1-agent-api-decide-endpoint-recommended)
- [Method 2: Feature Experimentation API](#method-2-feature-experimentation-api)
- [Method 3: Traditional Experiments API (Limited)](#method-3-traditional-experiments-api-limited)
- [Comparison and Tradeoffs](#comparison-and-tradeoffs)
- [Recommendations](#recommendations)

## Overview of Available APIs

Optimizely provides three main API approaches for retrieving user experiments:

1. **Optimizely Agent API** - Real-time decision engine for user-specific assignments
2. **Feature Experimentation API** - Administrative API for managing flags and experiments
3. **Traditional Experiments API** - Legacy approach with limited availability

Each approach serves different use cases and has distinct advantages and limitations.

## Method 1: Agent API Decide Endpoint (Recommended)

The Agent API's decide endpoint is the most direct way to get user-specific experiment assignments and feature flag decisions.

### Authentication
```bash
# SDK Key required - find it in Optimizely app under Settings > Environments
X-Optimizely-SDK-Key: YOUR_SDK_KEY
```

### Get All Experiments for a User

```bash
curl --location --request POST 'http://localhost:8080/v1/decide' \
  --header 'X-Optimizely-SDK-Key: YOUR_SDK_KEY' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "userId": "user123",
    "userAttributes": {
      "premium": true,
      "country": "US",
      "age": 28
    },
    "decideOptions": ["ENABLED_FLAGS_ONLY"]
  }'
```

### Get Specific Experiments

```bash
curl --location --request POST 'http://localhost:8080/v1/decide?keys=checkout_flow&keys=recommendation_engine' \
  --header 'X-Optimizely-SDK-Key: YOUR_SDK_KEY' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "userId": "user123",
    "userAttributes": {
      "premium": true
    }
  }'
```

### Example Response

```json
[
  {
    "flagKey": "checkout_flow",
    "enabled": true,
    "variationKey": "new_checkout",
    "ruleKey": "ab_test_checkout_v2",
    "variables": {
      "button_color": "blue",
      "steps": 3,
      "show_progress": true
    },
    "reasons": ["FLAG_RULE_AUDIENCE_MATCH"]
  },
  {
    "flagKey": "recommendation_engine",
    "enabled": true,
    "variationKey": "ml_enhanced",
    "ruleKey": "recommendations_experiment",
    "variables": {
      "algorithm": "collaborative_filtering",
      "max_items": 10
    },
    "reasons": ["FLAG_RULE_AUDIENCE_MATCH"]
  },
  {
    "flagKey": "premium_features",
    "enabled": false,
    "variationKey": "off",
    "ruleKey": null,
    "variables": {},
    "reasons": ["FLAG_NOT_FOUND"]
  }
]
```

### JavaScript Implementation

```javascript
async function getUserExperiments(userId, userAttributes = {}) {
  const response = await fetch('http://localhost:8080/v1/decide', {
    method: 'POST',
    headers: {
      'X-Optimizely-SDK-Key': process.env.OPTIMIZELY_SDK_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      userId,
      userAttributes,
      decideOptions: ['ENABLED_FLAGS_ONLY']
    })
  });

  return await response.json();
}

// Usage
const experiments = await getUserExperiments('user123', {
  premium: true,
  country: 'US'
});

console.log(`User assigned to ${experiments.length} experiments`);
```

### Python Implementation

```python
import requests
import os

def get_user_experiments(user_id, user_attributes=None):
    url = 'http://localhost:8080/v1/decide'
    headers = {
        'X-Optimizely-SDK-Key': os.getenv('OPTIMIZELY_SDK_KEY'),
        'Content-Type': 'application/json'
    }

    payload = {
        'userId': user_id,
        'userAttributes': user_attributes or {},
        'decideOptions': ['ENABLED_FLAGS_ONLY']
    }

    response = requests.post(url, json=payload, headers=headers)
    return response.json()

# Usage
experiments = get_user_experiments('user123', {
    'premium': True,
    'country': 'US'
})

print(f"User assigned to {len(experiments)} experiments")
```

## Method 2: Feature Experimentation API

The Feature Experimentation API provides administrative access to flags and experiments but requires additional logic to determine user assignments.

### Authentication
```bash
# Bearer token required
Authorization: Bearer YOUR_API_TOKEN
```

### List All Flags

```bash
curl --location --request GET 'https://api.optimizely.com/flags/v1/projects/{project_id}/flags' \
  --header 'Authorization: Bearer YOUR_API_TOKEN'
```

### Example Response

```json
{
  "flags": [
    {
      "id": "flag_123",
      "key": "checkout_flow",
      "name": "New Checkout Flow",
      "description": "A/B test for streamlined checkout",
      "archived": false,
      "variations": [
        {
          "id": "var_1",
          "key": "control",
          "name": "Control"
        },
        {
          "id": "var_2",
          "key": "new_checkout",
          "name": "New Checkout"
        }
      ]
    }
  ],
  "totalCount": 15
}
```

### Get Flag Ruleset for Targeting Logic

```bash
curl --location --request GET 'https://api.optimizely.com/flags/v1/projects/{project_id}/flags/{flag_key}/environments/{environment_key}/ruleset' \
  --header 'Authorization: Bearer YOUR_API_TOKEN'
```

### JavaScript Implementation

```javascript
async function getAllFlags(projectId) {
  const response = await fetch(`https://api.optimizely.com/flags/v1/projects/${projectId}/flags`, {
    headers: {
      'Authorization': `Bearer ${process.env.OPTIMIZELY_API_TOKEN}`
    }
  });

  return await response.json();
}

async function getFlagRuleset(projectId, flagKey, environment) {
  const response = await fetch(
    `https://api.optimizely.com/flags/v1/projects/${projectId}/flags/${flagKey}/environments/${environment}/ruleset`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.OPTIMIZELY_API_TOKEN}`
      }
    }
  );

  return await response.json();
}

// Usage - requires additional logic to determine user assignments
const flags = await getAllFlags('your_project_id');
// You would need to implement targeting logic based on ruleset
```

## Method 3: Traditional Experiments API (Limited)

The traditional Experiments API has limited functionality in Feature Experimentation.

### List Experiments (Limited Availability)

```bash
curl --location --request GET 'https://api.optimizely.com/v2/experiments' \
  --header 'Authorization: Bearer YOUR_API_TOKEN'
```

**⚠️ Important:** Most experiment endpoints are not available in Optimizely Feature Experimentation, except for experiment results.

## Comparison and Tradeoffs

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Agent API Decide** | • Real-time user assignments<br>• Handles targeting logic<br>• Returns actual decisions<br>• Supports user attributes | • Requires running Agent<br>• SDK key authentication only | User-facing applications needing real-time decisions |
| **Feature Experimentation API** | • Administrative access<br>• Bearer token auth<br>• Full flag metadata<br>• No Agent required | • No automatic user targeting<br>• Requires custom targeting logic<br>• Rate limited (2 req/sec) | Admin dashboards, configuration management |
| **Traditional Experiments API** | • Familiar REST patterns | • Limited availability<br>• Legacy approach<br>• Not recommended for new implementations | Legacy integrations (not recommended) |

### Performance Considerations

- **Agent API**: Fastest for user decisions, optimized for real-time use
- **Feature Experimentation API**: Rate limited to 2 requests/second, 120/minute
- **Agent API** processes targeting rules server-side vs. client-side logic

### Security Considerations

- **SDK Keys** (Agent API): Environment-specific, safer for client-side use
- **API Tokens** (Feature Experimentation API): More powerful, server-side only
- **User Context**: Agent API accepts user attributes for targeting

## Recommendations

### For Real-Time User Decisions (Recommended)
Use the **Agent API decide endpoint** when you need to:
- Get actual experiment assignments for users
- Handle targeting and segmentation automatically
- Make real-time decisions in your application
- Support user attributes for targeting

### For Administrative Tasks
Use the **Feature Experimentation API** when you need to:
- Build admin dashboards
- Manage flag configurations
- Audit experiment setups
- Integrate with CI/CD pipelines

### Architecture Recommendations

1. **Microservices**: Deploy Optimizely Agent as a sidecar or dedicated service
2. **Edge Computing**: Use Agent API at edge locations for low latency
3. **Caching**: Cache decide responses when appropriate (consider user context changes)
4. **Monitoring**: Track decision latency and Agent health

### Code Organization

```javascript
// Recommended: Abstraction layer
class OptimizelyClient {
  async getUserDecisions(userId, attributes) {
    // Use Agent API for real-time decisions
    return this.agentAPI.decide(userId, attributes);
  }

  async getExperimentConfig(flagKey) {
    // Use Admin API for configuration
    return this.adminAPI.getFlag(flagKey);
  }
}
```

## Conclusion

The Agent API's decide endpoint is the recommended approach for fetching user experiments in 2024. It provides real-time, user-specific decisions with built-in targeting logic, making it ideal for most application scenarios. Reserve the Feature Experimentation API for administrative tasks and avoid the traditional Experiments API for new implementations.

Choose the Agent API when you need user decisions, and the Feature Experimentation API when you need to manage the experiments themselves.