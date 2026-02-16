# Spring AI

## 1. What is it?

Spring AI is an application framework for AI engineering, built by the Spring team (VMware/Broadcom). It brings Spring ecosystem conventions -- dependency injection, auto-configuration, portable abstractions -- to the domain of generative AI. It lets Java/Spring Boot developers integrate AI models (chat, embedding, image generation, transcription) into their applications using familiar patterns, without learning Python-based AI tooling. It reached GA (1.0) in May 2025, and Spring AI 2.0.0-M1 is already in development, built on Spring Boot 4.0 and Spring Framework 7.0.

The project draws inspiration from Python projects like LangChain and LlamaIndex but is not a direct port.

- GitHub: github.com/spring-projects/spring-ai
- License: Apache 2.0

## 2. Main Features

- Portable Chat/Embedding/Image/Transcription model abstractions -- swap providers without changing application code
- Multi-provider support -- OpenAI, Anthropic, Google Vertex AI, Amazon Bedrock, Azure OpenAI, Ollama, Mistral, and more
- Structured output -- map AI model responses directly to Java POJOs
- Retrieval Augmented Generation (RAG) -- built-in support with vector store integrations
- Vector database support -- Cassandra, Chroma, Milvus, MongoDB Atlas, Neo4j, Pinecone, PgVector, Qdrant, Redis, Weaviate
- Function/Tool calling -- let the LLM invoke Java methods as tools
- Chat memory -- conversation history management with compaction and retention policies
- ETL framework for document ingestion -- loaders for S3, MongoDB, PDF, and more
- Advisors API -- interceptor-like pattern for cross-cutting concerns (memory, logging, RAG)
- Model Context Protocol (MCP) support -- interoperable composable AI services
- Observability -- Spring Boot Actuator integration with Micrometer, Zipkin, Datadog, Splunk
- Streaming support -- reactive Flux-based streaming responses
- GraalVM native image support -- compile to native executables
- Spring Security integration -- enterprise-grade security out of the box

## 3. Pros

- Seamless Spring Boot integration -- if your organization already uses Spring, adoption is natural
- Vendor lock-in prevention -- portable abstractions mean switching AI providers requires minimal code changes
- Enterprise-grade -- security, scalability, observability, and production patterns built in
- Structured outputs -- first-class mapping of LLM responses to typed Java objects
- Mature ecosystem -- inherits the entire Spring ecosystem (Spring Data, Spring Security, Spring Cloud)
- ETL pipeline support -- dedicated document ingestion pipeline
- Active development -- backed by the Spring team with rapid release cadence
- Consistent API design -- follows the same patterns Java developers already know (Builder, fluent APIs, auto-configuration)
- Strong community -- 25+ community repositories, official spring-ai-examples repo

## 4. Cons

- JVM only -- limited to Java/Kotlin/Groovy; does not serve the Python-dominated AI research community
- Relatively new -- GA only since May 2025, so fewer battle-tested production stories compared to LangChain
- Heavyweight for simple use cases -- Spring Boot's auto-configuration and dependency injection can be overkill for a quick script
- Rapidly evolving API -- breaking changes between 1.x and 2.x
- Smaller tool/integration ecosystem -- Python frameworks have far more pre-built tools, loaders, and integrations
- AI research gap -- most cutting-edge AI research, papers, and reference implementations are in Python first
- Learning curve for non-Spring developers -- requires familiarity with Spring Boot conventions

## 5. Comparison

| Aspect | Spring AI | Strands Agents | CrewAI | LangChain | AWS AgentCore |
|---|---|---|---|---|---|
| Language | Java (JVM) | Python, TypeScript | Python | Python, JS/TS | Any (managed service) |
| Primary Focus | AI-powered Spring Boot apps | Model-driven autonomous agents | Multi-agent role-based orchestration | LLM app orchestration | Agent deployment and operations |
| Agent Support | Advisors + tool calling | First-class agents with tool autonomy | First-class multi-agent crews | Agents, chains, LangGraph | Framework-agnostic agent runtime |
| Multi-Agent | Basic (via advisors) | Graph, Swarm, Workflow patterns | Core feature | LangGraph multi-agent | Runs agents from any framework |
| RAG Support | Built-in with vector stores + ETL | Via tools/MCP | Via tools | Core feature | Not built-in |
| Model Providers | OpenAI, Anthropic, Google, AWS, Azure, Ollama | Bedrock, OpenAI, Anthropic, Ollama, Gemini | OpenAI, Anthropic, local models | 100+ integrations | Bedrock, OpenAI, Gemini |
| Observability | Spring Actuator, Micrometer | OpenTelemetry | Built-in tracing | LangSmith | Built-in monitoring |
| MCP Support | Yes | Yes (first-class) | Limited | Yes | Yes (Gateway) |
| Best For | Java enterprise teams adding AI | AWS-centric teams building agents | Teams needing multi-agent collaboration | Rapid prototyping, broad integrations | Deploying agents at scale on AWS |

## 6. Why is it unique?

Spring AI is the only production-grade AI framework built natively for the Java/Spring ecosystem. It was designed from scratch to follow Spring conventions (dependency injection, auto-configuration, starter POMs), making it feel native to Java developers rather than a translation layer. It treats AI as another Spring integration concern, just as Spring Data abstracts databases and Spring Security abstracts auth. Structured output mapping to POJOs is a first-class feature, far more natural in a statically-typed language like Java. Its primary audience is the massive installed base of enterprise Java applications that want to add AI features to existing production systems, inheriting the entire Spring ecosystem -- Spring Security, Spring Data, Spring Cloud, GraalVM native images -- which no Python framework can replicate for JVM workloads.

## 7. Simple Usage

Maven dependency (pom.xml):
```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-model-openai</artifactId>
</dependency>
```

application.properties:
```properties
spring.ai.openai.api-key=${OPENAI_API_KEY}
spring.ai.openai.chat.options.model=gpt-4o
```

Controller:
```java
package com.app;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ChatController {

    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    @GetMapping("/chat")
    public String chat(@RequestParam String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
```

Structured output (mapping to a POJO):
```java
record CityInfo(String name, String country, int population, String famousFor) {}

@GetMapping("/city")
public CityInfo city() {
    return chatClient.prompt()
            .user("Tell me about Tokyo")
            .call()
            .entity(CityInfo.class);
}
```
