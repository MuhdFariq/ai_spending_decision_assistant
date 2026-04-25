from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import requests

from app.config import ZAI_API_KEY

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ExpenseItem(BaseModel):
    title: str = ""
    amount: float = 0.0
    category: str = ""


class RequestData(BaseModel):
    user_question: str = ""
    remaining_budget: float = 0.0
    feature_type: str = "chat"
    amount: float = 0.0
    recent_expenses: List[ExpenseItem] = []


@app.get("/")
def root():
    return {"message": "Backend is running"}


def call_glm(prompt: str):
    url = "https://api.ilmu.ai/v1/chat/completions"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {ZAI_API_KEY}",
    }

    payload = {
        "model": "ilmu-glm-5.1",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }

    print("CALL_GLM TEST PAYLOAD:", payload)

    response = requests.post(url, headers=headers, json=payload, timeout=30)

    print("GLM STATUS CODE:", response.status_code)
    print("GLM RESPONSE TEXT:", response.text)

    if response.status_code != 200:
        raise Exception(f"GLM failed: {response.status_code} - {response.text}")

    data = response.json()
    content = data["choices"][0]["message"]["content"]

    if content is None:
        raise Exception(f"GLM content was None. Full body: {response.text}")

    return content


@app.post("/ai/respond")
def respond(data: RequestData):
    budget = data.remaining_budget
    expenses = data.recent_expenses
    print("=== AI REQUEST ===")
    print("QUESTION:", data.user_question)
    print("BUDGET:", data.remaining_budget)
    print("EXPENSES:", [(e.title, e.amount, e.category) for e in expenses])
    total_recent = sum(item.amount for item in expenses)

    if data.feature_type == "categorize":
        try:
            prompt = f"""
            Categorize this expense: "{data.user_question}"

            Choose ONLY one category from:
            Food, Transport, Shopping, Bills, Others

            Respond EXACTLY like:
            Answer: <category>
            Reason: <short reason>
            BasedOn: <what you used>
            """

            glm_text = call_glm(prompt)
            lines = [line.strip() for line in glm_text.split("\n") if line.strip()]

            answer = ""
            reason = ""
            based_on = ""

            for line in lines:
                lower = line.lower()
                if lower.startswith("answer:"):
                    answer = line.split(":", 1)[1].strip()
                elif lower.startswith("reason:"):
                    reason = line.split(":", 1)[1].strip()
                elif lower.startswith("basedon:") or lower.startswith("based on:"):
                    based_on = line.split(":", 1)[1].strip()

            return {
                "answer": answer or "Others",
                "reason": reason or "Categorized by GLM",
                "basedOn": based_on or data.user_question,
                "source": "glm",
            }

        except Exception as e:
            print("CATEGORIZE ERROR:", str(e))

            note = data.user_question.lower()

            if any(word in note for word in ["lunch", "dinner", "breakfast", "mcd", "kfc", "meal", "food", "eat", "drink", "coffee", "nandos"]):
                fallback_category = "Food"
            elif any(word in note for word in ["grab", "bus", "train", "lrt", "mrt", "taxi", "ride", "petrol", "transport"]):
                fallback_category = "Transport"
            elif any(word in note for word in ["shirt", "shoes", "hat", "mall", "clothes", "shopping"]):
                fallback_category = "Shopping"
            elif any(word in note for word in ["bill", "electric", "water", "internet", "phone", "rent"]):
                fallback_category = "Bills"
            else:
                fallback_category = "Others"

            return {
                "answer": fallback_category,
                "reason": "Fallback categorization based on keywords",
                "basedOn": data.user_question,
                "source": "glm_failed",
            }

    try:
        prompt = f"""
        User question: {data.user_question}

        Current remaining budget after recent expenses: RM{data.remaining_budget}
        Recent expenses, already sorted from newest to oldest:
        {[(e.title, e.amount, e.category) for e in data.recent_expenses]}

        If the user asks for recent spending, use the first items in this list.
        Do not reverse the list.
        Do not subtract recent expenses from the remaining budget again.

        Respond EXACTLY in this format:
        Answer:
        Reason:
        BasedOn:
        """

        glm_text = call_glm(prompt)
        lines = [line.strip() for line in glm_text.split("\n") if line.strip()]

        answer = ""
        reason = ""
        based_on = ""

        i = 0
        while i < len(lines):
            line = lines[i]
            lower = line.lower()

            if lower == "answer:" and i + 1 < len(lines):
                answer = lines[i + 1]
                i += 1
            elif lower.startswith("answer:"):
                answer = line.split(":", 1)[1].strip()
            elif lower == "reason:" and i + 1 < len(lines):
                reason = lines[i + 1]
                i += 1
            elif lower.startswith("reason:"):
                reason = line.split(":", 1)[1].strip()
            elif (lower == "basedon:" or lower == "based on:") and i + 1 < len(lines):
                based_on = lines[i + 1]
                i += 1
            elif lower.startswith("basedon:") or lower.startswith("based on:"):
                based_on = line.split(":", 1)[1].strip()

            i += 1

        return {
            "answer": answer or glm_text,
            "reason": reason or "Generated by GLM",
            "basedOn": based_on or f"Remaining budget RM{budget:.2f}",
            "source": "glm",
        }

    except Exception as e:
        print("GLM ERROR:", str(e))

    import re

    question = data.user_question.lower()

    # Handle "recent spending" deterministically (not via AI)
    if "recent" in question and ("spending" in question or "expense" in question):
        recent_items = expenses[:4]

        answer = "\n".join(
            f"{i+1}. {item.title} - RM{item.amount:.2f} ({item.category or 'Others'})"
            for i, item in enumerate(recent_items)
        )

        return {
            "answer": answer,
            "reason": "These are the most recent expenses provided by the app, sorted from newest to oldest.",
            "basedOn": "Recent expenses list",
            "source": "deterministic",
        }
        
    match = re.search(r'(?:rm\s*)?(\d+(?:\.\d+)?)', question)
    detected_amount = float(match.group(1)) if match else None

    if data.feature_type == "affordability":
        amount = data.amount

        if amount <= budget * 0.3:
            answer = "Yes"
            reason = "This purchase is small relative to your remaining budget."
        elif amount <= budget:
            answer = "Be careful"
            reason = "You can afford it, but it may reduce future flexibility."
        else:
            answer = "No"
            reason = "This exceeds your remaining budget."

        based_on = (
            f"Based on budget RM{budget:.2f}, "
            f"purchase RM{amount:.2f}, "
            f"and {len(expenses)} expense records."
        )

    elif detected_amount is not None:
        if detected_amount <= budget:
            answer = f"Yes, you can afford RM{detected_amount:.2f}."
            reason = "The amount is within your remaining budget."
        else:
            answer = f"No, you cannot afford RM{detected_amount:.2f}."
            reason = "The amount exceeds your remaining budget."

        based_on = (
            f"Based on remaining budget RM{budget:.2f} "
            f"and requested amount RM{detected_amount:.2f}."
        )

    else:
        category_totals = {}

        for item in expenses:
            category = item.category if item.category else "Others"
            category_totals[category] = category_totals.get(category, 0) + item.amount

        if category_totals:
            top_category = max(category_totals, key=category_totals.get)
            top_amount = category_totals[top_category]

            if "reduce" in question or "cut" in question or "save" in question:
                answer = f"Reduce spending in {top_category} first."
                reason = f"{top_category} is currently your highest spending category."
            elif "overspending" in question or "over spending" in question:
                answer = f"Your main overspending area appears to be {top_category}."
                reason = f"{top_category} has the highest total spending among your recent expenses."
            else:
                answer = "Review your highest spending category first."
                reason = f"{top_category} is the largest spending area right now."

            based_on = (
                f"RM{top_amount:.2f} spent in {top_category}, "
                f"with RM{budget:.2f} remaining budget."
            )
        else:
            answer = "There is not enough spending data to give advice yet."
            reason = "No recent expenses were provided to analyse."
            based_on = f"Remaining budget RM{budget:.2f}."

    return {
        "answer": answer,
        "reason": reason,
        "basedOn": based_on,
        "source": "glm_failed",
    }