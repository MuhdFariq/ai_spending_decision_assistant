# System Architecture – AI Financial Decision Assistant

## 1. Overview

This system is an AI-powered financial decision assistant designed to help users make informed spending decisions.

The system integrates a conversational AI interface, affordability checking logic, and an explainability layer to ensure all outputs are transparent and grounded in user data.

The architecture follows a client-server model with an AI service layer that interfaces with Z.AI’s GLM.

---

## 2. High-Level Components

### Frontend (Flutter Mobile App)
- Chat Interface (AI Chat Screen)
- Affordability Checker Screen
- Displays responses in structured format (Answer / Reason / Based on)

### Backend / Logic Layer (Local or FastAPI-ready)
- Insight Service (handles chat queries and context building)
- Affordability Logic (budget evaluation)
- Explainability Service (enforces structured output format)

### AI Service Layer (GLM Integration)
- GLM Service (handles prompt construction and API calls)
- Fallback Logic (used when GLM is unavailable)
- Response Parsing & Formatting

### Data Layer
- Mock Data Service (current)
  - User expenses
  - Budget information
- Future: Database (e.g. PostgreSQL / Firebase)

---

## 3. System Flow (Chat Feature)

1. User enters a question in Chat Interface  
2. Frontend sends query to Insight Service  
3. Insight Service retrieves:
   - recent expenses  
   - current budget  
4. Context is constructed into a structured prompt  
5. System checks:
   - If GLM available → send to GLM Service  
   - Else → use fallback logic  
6. Response is passed to Explainability Service  
7. Output is formatted into:
   - Answer  
   - Reason  
   - Based on  
8. Frontend displays structured response  

---

## 4. System Flow (Affordability Checker)

1. User inputs item name and amount  
2. Frontend sends data to affordability logic  
3. System retrieves:
   - remaining budget  
   - recent spending trends  
4. Decision logic evaluates:
   - YES → safe to spend  
   - BE CAREFUL → borderline  
   - NO → exceeds safe threshold  
5. Explanation is generated using explainability layer  
6. Structured response returned to UI  

---

## 5. GLM Integration Design

### Prompt Construction
The system constructs prompts using:
- user query  
- recent expense data  
- remaining budget  
- spending trends  

### Context Handling
- Only recent data (e.g. last 7 days) is included  
- Input size is controlled to avoid token overflow  
- Future: chunking if data exceeds limits  

### Response Handling
- Raw GLM output is NOT directly shown  
- Output passes through Explainability Service  
- Format is enforced:
  - Answer  
  - Reason  
  - Based on  

### Fallback Mechanism
- If GLM fails or is unavailable:
  - system uses rule-based fallback logic  
  - still returns structured explainable output  

---

## 6. Key Design Decisions

### Explainability First
All AI outputs must include reasoning and data reference to meet decision intelligence requirements.

### Separation of Concerns
- UI handles interaction only  
- Services handle logic  
- AI layer handles reasoning  

### Resilience
System is designed to function even without GLM using fallback logic, ensuring demo reliability.

### GLM as Core Reasoning Layer
The system is designed such that removing GLM reduces the system’s ability to generate intelligent insights.

---

## 7. Future Enhancements

- Replace mock data with real database  
- Enable real-time expense tracking  
- Add predictive spending analysis  
- Improve personalization of recommendations  
- Optimize prompt efficiency and token usage  

---

## 8. Summary

The system is designed as a modular, AI-integrated architecture where decision-making, reasoning, and explainability are central.

The combination of structured logic, GLM integration, and fallback mechanisms ensures both reliability and intelligent output, aligning with the goals of decision intelligence systems.