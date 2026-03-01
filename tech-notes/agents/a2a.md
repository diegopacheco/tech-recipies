# Agent 2 Agent Protocol (A2A)

## 1. What is A2A?

A2A (Agent2Agent) is an open protocol created by Google in April 2025 that enables AI agents to communicate with each other, exchange information, and coordinate actions across different platforms and vendors. The protocol was contributed to the Linux Foundation in June 2025, making it a vendor-neutral open standard. A2A is built on top of established web standards like HTTP, JSON-RPC, and SSE (Server-Sent Events). It complements Anthropic's Model Context Protocol (MCP), where MCP provides tools and context to agents, A2A enables agent-to-agent collaboration. A2A treats agents as opaque entities, meaning they can collaborate without exposing their internal logic, memory, or proprietary implementations.

## 2. How it Works?

A2A works through four core mechanisms:

**Agent Cards**: Each agent publishes an "Agent Card" (a JSON document) that describes its capabilities, skills, supported input/output modes, and endpoint URLs. Other agents discover what an agent can do by reading its Agent Card, similar to how OpenAPI specs describe REST APIs.

**Task Management**: When an agent wants another agent to do something, it creates a Task. Tasks have a defined lifecycle with states like submitted, working, input-required, completed, canceled, and failed. Tasks can be short-lived or long-running with status tracking and real-time feedback.

**Message Exchange**: Agents communicate by exchanging Messages within a Task. Each message contains Parts (text, files, structured data, audio, video). Messages flow between a "client" agent and a "remote" agent using JSON-RPC over HTTP or gRPC.

**Streaming & Push Notifications**: For real-time interactions, A2A supports Server-Sent Events (SSE) for streaming responses and push notifications for async updates on long-running tasks.

The typical flow is:
1. Client agent discovers a remote agent via its Agent Card
2. Client sends a message to create or continue a Task
3. Remote agent processes the request and responds with updates
4. Task progresses through its lifecycle until completion

## 3. PROS

- **Interoperability**: Vendor-agnostic protocol that lets agents from different platforms (Google, Salesforce, SAP) work together seamlessly
- **Built on Standards**: Uses HTTP, JSON-RPC, SSE, and gRPC making it easy to adopt within existing enterprise infrastructure
- **Privacy & IP Protection**: Agents are treated as opaque, they collaborate without revealing internal logic or proprietary implementations
- **Multimodal Support**: Handles text, audio, video, images, and structured data in a single protocol
- **Long-Running Task Support**: First-class support for tasks that take hours or days, with status tracking and notifications
- **Enterprise Security**: Supports standard authentication and authorization mechanisms aligned with OpenAPI security schemes
- **Linux Foundation Governance**: Open governance model ensures no single vendor controls the protocol
- **Streaming**: Real-time streaming via SSE allows responsive agent interactions
- **Strong Ecosystem**: 150+ organizations supporting the protocol with official SDKs for Java, Python, TypeScript, and Go

## 4. CONS

- **Ecosystem Fragmentation**: Introduces yet another protocol alongside MCP, creating confusion about when to use which
- **Complexity**: Managing multi-agent workflows across A2A tasks, agent communications, and MCP tool interactions adds debugging complexity
- **Immature Tooling**: Integrated monitoring and debugging tools that cover both A2A and MCP don't exist yet
- **Inconsistent Implementations**: Different agents may handle headers, authentication schemes, timeouts, and retry logic differently
- **Security Surface**: Agent discovery via Agent Cards can expose agents to attackers who exploit vulnerabilities through tool squatting or fake agent registration
- **Overhead for Simple Cases**: For straightforward tool-calling scenarios, MCP alone is simpler and A2A adds unnecessary ceremony
- **Still Evolving**: Protocol is at version 0.3, meaning breaking changes are still possible
- **Google-Centric Origins**: Despite Linux Foundation governance, the protocol was designed primarily around Google's agent ecosystem patterns

## 5. Use Cases

- **Enterprise Workflow Orchestration**: A travel booking agent coordinates with airline, hotel, and car rental agents to build a complete itinerary
- **Cross-Platform Agent Collaboration**: A Salesforce CRM agent communicates with a SAP ERP agent to sync customer data and trigger supply chain actions
- **Multi-Vendor AI Pipelines**: A research agent from one vendor gathers data while an analysis agent from another vendor processes and summarizes findings
- **Customer Support Escalation**: A front-line support agent hands off complex issues to specialized agents (billing, technical, returns) while maintaining context
- **Financial Services**: An investment analysis agent queries multiple data provider agents (market data, news, risk assessment) and consolidates results
- **Healthcare Coordination**: A patient intake agent coordinates with scheduling, insurance verification, and medical records agents across different hospital systems
- **Supply Chain Management**: Procurement agents negotiate with supplier agents across different organizations in real-time
- **Code Review & DevOps**: A CI/CD agent delegates security scanning, code review, and deployment tasks to specialized agents

## 6. Who is Using it?

**Technology Partners (50+)**:
Google, Atlassian, Box, Cohere, Intuit, LangChain, MongoDB, PayPal, Salesforce, SAP, ServiceNow, UKG, Workday, Adobe, Confluent, S&P Global Market Intelligence

**Consulting & Service Providers**:
Accenture, BCG, Capgemini, Cognizant, Deloitte, HCLTech, Infosys, KPMG, McKinsey, PwC, TCS, Wipro

**Framework & Platform Support**:
Spring AI (VMware/Broadcom), Quarkus (Red Hat), LangChain, CrewAI, Google ADK (Agent Development Kit)

**Governance**:
Linux Foundation (hosts the A2A project as an open-source initiative)

## 7. Code Sample with Java

Using the official A2A Java SDK (`a2a-java`).

### Server Side - Agent Card Producer

```java
package io.a2a.myagent;

import java.util.Collections;
import java.util.List;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

import io.a2a.server.PublicAgentCard;
import io.a2a.spec.AgentCapabilities;
import io.a2a.spec.AgentCard;
import io.a2a.spec.AgentInterface;
import io.a2a.spec.AgentSkill;

@ApplicationScoped
public class MyAgentCardProducer {

    @Produces
    @PublicAgentCard
    public AgentCard agentCard() {
        return AgentCard.builder()
                .name("Translation Agent")
                .description("Translates text between languages")
                .supportedInterfaces(Collections.singletonList(
                    new AgentInterface("JSONRPC", "http://localhost:9999")))
                .version("1.0.0")
                .capabilities(AgentCapabilities.builder()
                        .streaming(true)
                        .pushNotifications(false)
                        .build())
                .defaultInputModes(Collections.singletonList("text"))
                .defaultOutputModes(Collections.singletonList("text"))
                .skills(Collections.singletonList(AgentSkill.builder()
                        .id("translate")
                        .name("Translate Text")
                        .description("Translates text to a target language")
                        .tags(List.of("translation", "language"))
                        .examples(List.of("translate hello to Spanish",
                                          "convert this to French"))
                        .build()))
                .build();
    }
}
```

### Server Side - Agent Executor

```java
package io.a2a.myagent;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

import io.a2a.server.agentexecution.AgentExecutor;
import io.a2a.server.agentexecution.RequestContext;
import io.a2a.server.tasks.AgentEmitter;
import io.a2a.spec.A2AError;
import io.a2a.spec.TextPart;
import io.a2a.spec.UnsupportedOperationError;

@ApplicationScoped
public class MyAgentExecutorProducer {

    @Produces
    public AgentExecutor agentExecutor() {
        return new AgentExecutor() {
            @Override
            public void execute(RequestContext context, AgentEmitter emitter) throws A2AError {
                String input = context.getMessage().getParts().stream()
                        .filter(p -> p instanceof TextPart)
                        .map(p -> ((TextPart) p).getText())
                        .findFirst()
                        .orElse("");

                String translated = translateText(input);
                emitter.sendMessage(translated);
            }

            @Override
            public void cancel(RequestContext context, AgentEmitter emitter) throws A2AError {
                throw new UnsupportedOperationError();
            }

            private String translateText(String input) {
                return "Translated: " + input;
            }
        };
    }
}
```

### Client Side - Calling the Remote Agent

```java
package io.a2a.myagent;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

import io.a2a.client.Client;
import io.a2a.client.ClientBuilder;
import io.a2a.client.ClientEvent;
import io.a2a.client.MessageEvent;
import io.a2a.client.http.A2ACardResolver;
import io.a2a.client.transport.jsonrpc.JSONRPCTransport;
import io.a2a.client.transport.jsonrpc.JSONRPCTransportConfig;
import io.a2a.spec.AgentCard;
import io.a2a.spec.Message;
import io.a2a.spec.Part;
import io.a2a.spec.TextPart;

public class TranslationClient {

    public static void main(String[] args) throws Exception {
        String serverUrl = "http://localhost:9999";

        A2ACardResolver resolver = new A2ACardResolver(serverUrl);
        AgentCard agentCard = resolver.getAgentCard();

        System.out.println("Connected to: " + agentCard.name());

        CompletableFuture<String> resultFuture = new CompletableFuture<>();

        List<Consumer<? extends ClientEvent>> consumers = new ArrayList<>();
        consumers.add((Consumer<MessageEvent>) event -> {
            Message message = event.message();
            for (Part part : message.parts()) {
                if (part instanceof TextPart textPart) {
                    System.out.println("Response: " + textPart.text());
                    resultFuture.complete(textPart.text());
                }
            }
        });

        BiConsumer<Throwable, String> streamingErrorHandler = (error, msg) -> {
            System.err.println("Error: " + msg);
            error.printStackTrace();
            resultFuture.completeExceptionally(error);
        };

        Client client = Client.builder(agentCard)
                .addConsumers(consumers)
                .streamingErrorHandler(streamingErrorHandler)
                .withTransport(JSONRPCTransport.class, new JSONRPCTransportConfig())
                .build();

        client.sendMessage("Translate 'hello world' to Spanish");

        String result = resultFuture.get();
        System.out.println("Translation result: " + result);
    }
}
```

### Maven Dependencies

```xml
<dependencies>
    <dependency>
        <groupId>io.github.a2asdk</groupId>
        <artifactId>a2a-java-sdk-server</artifactId>
        <version>0.3.0</version>
    </dependency>
    <dependency>
        <groupId>io.github.a2asdk</groupId>
        <artifactId>a2a-java-sdk-client</artifactId>
        <version>0.3.0</version>
    </dependency>
</dependencies>
```
