# SQL Evaluation Pipeline Refactor Roadmap (Reviewed & Refined)

## 1. Current Structure & Rationale
- The evaluation pipeline uses modular agent outputs for intent, execution, technical, and quality analysis.
- Results are aggregated and persisted, but current models and repository logic are tightly coupled and not fully extensible.
- The goal is to support multiple quality agents, agent-based aggregation, robust error handling, and efficient token usage.

---

## 2. Model Redesign for Aggregation & Extensibility
- **Aggregate Models:**
    ```python
    class ExecutionTechnicalResult(BaseModel):
        execution: ExecutionResult
        technical: TechnicalAnalysis

    class QualityEvaluation(BaseModel):
        educational: EducationalAnalysis
        assessment: Assessment
        recommendations: List[Recommendation]
        agent_id: Optional[str]
        error: Optional[str] = None

    class EvaluationResult(BaseModel):
        metadata: Dict[str, Any]
        intent: Intent
        execution_technical: ExecutionTechnicalResult
        quality_agents: List[QualityEvaluation]  # Multiple agent outputs
        quality_aggregate: Optional[QualityEvaluation]  # Aggregated result
        evaluated_at: datetime = Field(default_factory=datetime.now)
    ```
- **Benefits:**
    - Modular, extensible, and supports multi-agent quality assessment.
    - Error fields allow for partial results and robust error handling.
    - Aggregation is explicit and explainable.

---

## 3. Repository Refactor Strategy
- **Persistence Logic:**
    - Accepts lists of `QualityEvaluation` for multiple agents.
    - Stores `quality_aggregate` as the consensus result.
    - Handles optional error fields for agent failures or partial results.
    - Maintains backward compatibility during migration.
- **Migration:**
    - Support both legacy and new formats during transition.
    - Add tests for multi-agent persistence and error scenarios.

---

## 4. Error Handling & Robustness
- **Agent Failures:**
    - Capture errors in output models, log with agent ID and context.
    - Allow pipeline to continue with partial results.
- **Aggregation Conflicts:**
    - Use aggregation agent to resolve and explain conflicts.
    - Log rationale and unresolved issues.
- **Partial Results:**
    - Persist available outputs, mark missing stages as incomplete.
    - Report status in UI and reporting.
- **Testing:**
    - Validate error scenarios, aggregation correctness, and repository handling of partial/error results.

---

## 5. Agent-Based Quality Aggregation
- **Aggregation Agent:**
    - Synthesizes multiple quality agent outputs into a consensus result.
    - Merges recommendations, grades, scores, and provides rationale.
    - Receives all quality outputs and previous context (intent, execution, technical).
    - Example prompt:
        ```
        Given the following quality assessments from multiple agents:
        [quality_agent_outputs]
        Educational intent:
        [intent_result]
        Execution and technical analysis:
        [execution_technical_result]
        Aggregate these into a single quality evaluation, providing:
        - Consensus grade and score
        - Merged recommendations
        - Reasoning for the aggregate
        ```

---

## 6. Token Consumption & Resource Management
- **Token Tracking:**
    - Log token usage per agent and for the overall pipeline.
    - Use data to optimize prompts and manage cost.
    - Report total token consumption for each evaluation.

---

## 7. Implementation Checklist
- [ ] Redesign models for aggregation and extensibility
- [ ] Refactor repository logic for multi-agent and aggregate persistence
- [ ] Implement robust error handling and partial result support
- [ ] Integrate agent-based aggregation for quality assessment
- [ ] Track and report token usage
- [ ] Update reporting and UI for modular/aggregate results
- [ ] Add comprehensive tests for new logic and migration

---

## Notes
- This roadmap should be updated as refactor progresses.
- Specify affected models, repository methods, and reporting logic in each step.
- Use as a design reference and implementation checklist.
