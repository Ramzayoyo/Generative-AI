# Financial Assistant - Budget Manager & Expense Tracker (Jac)
# Features:
# - Set / update a budget (monthly or custom period)
# - Add expenses (with category, note, date)
# - Track remaining budget and trigger alerts at thresholds
# - Summary analytics (total, by category, percent used)
# - Export expenses as CSV (printed)

node Expense {
    has amount: float;
    has category: str;
    has note: str;
    has date: str;     # simple yyyy-mm-dd string
}

# Global storage (in-memory)
glob expenses = [];          # list of Expense nodes (or maps)
glob budget = {"limit": 0.0, "remaining": 0.0, "period": "monthly", "set_on": ""};

# Utility: create a simple ISO date string (yyyy-mm-dd)
def today_date() -> str {
    # If runtime provides date utilities you'd replace this.
    # Here we use a placeholder string to be replaced when calling functions externally.
    "2025-10-05";
}

# Set or update the main budget
def set_budget(amount: float, period: str, set_on: str = today_date()) -> dict {
    budget["limit"] = amount;
    budget["remaining"] = amount;
    budget["period"] = period;
    budget["set_on"] = set_on;
    return {"status": "ok", "budget": budget};
}

# Internal: check and print alerts when thresholds crossed
def check_budget_alerts() -> none {
    if budget["limit"] <= 0.0 {
        return;
    }
    used = budget["limit"] - budget["remaining"];
    pct_used = (used / budget["limit"]) * 100.0;
    if pct_used >= 100.0 {
        print("ALERT: You have exceeded your budget (100%+).");
    }
     else if pct_used >= 90.0 {
        print("ALERT: You have used 90% or more of your budget.");
    }
     else if pct_used >= 80.0 {
        print("WARNING: You have used 80% or more of your budget.");
    }
}

# Add expense: updates expenses list and budget.remaining, then triggers alerts
def add_expense(amount: float, category: str, note: str, date: str = today_date()) -> dict {
    e = Expense(amount=amount, category=category, note=note, date=date);
    expenses.append(e);
    # Update budget remaining if a budget is set
    if budget["limit"] > 0.0 {
        budget["remaining"] = budget["remaining"] - amount;
        if budget["remaining"] < 0.0 {
            budget["remaining"] = budget["remaining"]; # keep negative to show overspend
        }
    }
    check_budget_alerts();
    return {"status": "ok", "expense": {"amount": amount, "category": category, "note": note, "date": date}, "budget": budget};
}

# List all expenses (prints them) and returns the list
def list_expenses() -> list {
    print("Expenses:");
    idx = 1;
    for ex in expenses {
        print(f"{idx}. {ex.date} | {ex.category} | KSh {ex.amount} | {ex.note}");
        idx += 1;
    }
    return expenses;
}

# Sum total expenses
def total_expenses() -> float {
    total = 0.0;
    for ex in expenses {
        total += ex.amount;
    }
    return total;
}

# Summary by category (returns map category->total)
def summary_by_category() -> dict {
    summary = {};
    for ex in expenses {
        if ex.category in summary {
            summary[ex.category] += ex.amount;
        } else {
            summary[ex.category] = ex.amount;
        }
    }
    return summary;
}

# Print analytics summary
def print_summary() -> none {
    tot = total_expenses();
    print("---- Expense Summary ----");
    print(f"Total spent: KSh {tot}");
    if budget["limit"] > 0.0 {
        used = budget["limit"] - budget["remaining"];
        pct_used = (used / budget["limit"]) * 100.0;
        print(f"Budget limit: KSh {budget['limit']}");
        print(f"Used: KSh {used} ({round(pct_used, 2)}%)");
        print(f"Remaining: KSh {budget['remaining']}");
    } else {
        print("No budget set.");
    }
    cat_summary = summary_by_category();
    print("By category:");
    for k in cat_summary {
        print(f"- {k}: KSh {cat_summary[k]}");
    }
    print("-------------------------");
}

# Export expenses as CSV (printed so user can copy or redirect)
def export_csv() -> str {
    header = "date,category,amount,note";
    csv_text = header + "\n";
    for ex in expenses {
        # naive CSV – if notes include commas this is simplified
        csv_text += f"{ex.date},{ex.category},{ex.amount},{ex.note}\n";
    }
    print("CSV export:");
    print(csv_text);
    return csv_text;
}

# Simple automation example: send weekly summary (here, just prints)
def automated_weekly_summary() -> none {
    # In a real deployment you'd schedule this to run weekly.
    print("=== Automated Weekly Summary ===");
    print_summary();
    print("=== End Weekly Summary ===");
}

# Example entry walker: demonstrates usage and can be replaced by interactive calls
walker entry {
    # Demo flow - you can remove these demo calls when using interactively
    print("Financial Assistant starting demo...");

    # 1. Set budget (monthly)
    set_budget(50000.0, "monthly", "2025-10-01");
    print("Budget set to KSh 50,000 monthly.");

    # 2. Add several expenses
    add_expense(15000.0, "Rent", "October rent", "2025-10-02");
    add_expense(12000.0, "Food", "Groceries and market", "2025-10-03");
    add_expense(3000.0, "Transport", "Fuel & boda-boda", "2025-10-04");
    add_expense(2000.0, "Utilities", "Electricity", "2025-10-04");
    add_expense(5000.0, "Phone", "Airtime & data", "2025-10-05");

    # 3. List expenses and show summary
    list_expenses();
    print_summary();

    # 4. Export CSV (printed)
    export_csv();

    # 5. Run the automated weekly summary (demo)
    automated_weekly_summary();

    print("Demo finished. Replace demo calls with interactive logic as needed.");
}















# Financial Assistant - Local Budget & Expense Tracker with byllm hooks

import json

node Expense {
    has amount: float;
    has category: str;
    has note: str;
    has date: str;
}

glob expenses = [];
glob budget = {"limit": 0.0, "remaining": 0.0, "period": "monthly", "set_on": ""};

# Local storage filenames
const EXPENSE_FILE = "expenses.json";
const BUDGET_FILE = "budget.json";

# === Utility ===
def today_date() -> str {
    "2025-10-05"  # placeholder
}

# === Storage Helpers ===
def save_data() -> none {
    json.dump(expenses, EXPENSE_FILE);
    json.dump(budget, BUDGET_FILE);
    print("💾 Data saved locally.");
}

def load_data() -> none {
    try {
        expenses = json.load(EXPENSE_FILE);
        budget = json.load(BUDGET_FILE);
        print("📂 Data loaded successfully.");
    } catch {
        print("⚠ No saved data found, starting fresh.");
    }
}

# === Core Logic ===
def set_budget(amount: float, period: str, set_on: str = today_date()) -> dict {
    budget["limit"] = amount;
    budget["remaining"] = amount;
    budget["period"] = period;
    budget["set_on"] = set_on;
    save_data();
    return {"status": "ok", "budget": budget};
}

def check_budget_alerts() -> none {
    if budget["limit"] <= 0.0:
        return;
    used = budget["limit"] - budget["remaining"];
    pct_used = (used / budget["limit"]) * 100.0;
    if pct_used >= 100.0:
        print("🚨 ALERT: Budget exceeded!");
    elif pct_used >= 90.0:
        print("⚠ WARNING: You have used 90% of your budget.");
    elif pct_used >= 80.0:
        print("Heads-up: 80% of your budget is used.");
}

def add_expense(amount: float, category: str, note: str, date: str = today_date()) -> dict {
    e = Expense(amount=amount, category=category, note=note, date=date);
    expenses.append(e);
    if budget["limit"] > 0.0:
        budget["remaining"] -= amount;
    check_budget_alerts();
    save_data();
    return {"status": "ok", "expense": {"amount": amount, "category": category, "note": note, "date": date}};
}

def list_expenses() -> list {
    print("📘 All Expenses:");
    idx = 1;
    for ex in expenses:
        print(f"{idx}. {ex.date} | {ex.category} | {ex.amount} | {ex.note}");
        idx += 1;
    return expenses;
}

def total_expenses() -> float {
    total = 0.0;
    for ex in expenses:
        total += ex.amount;
    return total;
}

def summary_by_category() -> dict {
    summary = {};
    for ex in expenses:
        if ex.category in summary:
            summary[ex.category] += ex.amount;
        else:
            summary[ex.category] = ex.amount;
    return summary;
}

def print_summary() -> none {
    tot = total_expenses();
    print("---- 📊 Financial Summary ----");
    print(f"Total Spent: KSh {tot}");
    if budget["limit"] > 0.0:
        used = budget["limit"] - budget["remaining"];
        pct = (used / budget["limit"]) * 100.0;
        print(f"Budget: KSh {budget['limit']}");
        print(f"Used: {used} ({round(pct, 1)}%)");
        print(f"Remaining: KSh {budget['remaining']}");
    cat_sum = summary_by_category();
    print("Category Breakdown:");
    for k in cat_sum:
        print(f"  {k}: KSh {cat_sum[k]}");
    print("-----------------------------");
}

# === byllm Monitoring Hook ===
# byllm can call this periodically to analyze and summarize the financial data
def byllm_monitor() -> dict {
    report = {
        "total_expenses": total_expenses(),
        "budget_limit": budget["limit"],
        "remaining_budget": budget["remaining"],
        "by_category": summary_by_category(),
        "overspent": budget["remaining"] < 0.0
    }
    if report["overspent"]:
        print("🧠 byllm Alert: You are overspending. Recommend reviewing high categories.")
    else:
        print("🧠 byllm Summary generated successfully.")
    return report;
}

# === Example walker ===
walker entry {
    load_data();

    print("💼 Welcome to your Financial Assistant!");

    # Demo flow
    set_budget(60000.0, "monthly");
    add_expense(15000.0, "Rent", "October rent");
    add_expense(10000.0, "Food", "Groceries");
    add_expense(3000.0, "Transport", "Fuel");

    list_expenses();
    print_summary();

    # Trigger byllm monitoring
    byllm_monitor();
}