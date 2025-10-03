import from byllm {Model}
glob llm = Model(model_name= "gemini/gemini-2.0-flash");
def Agricultural_answer(prompt: str) -> str by llm();

with entry {
    print("Agricultural Assistant-your AI agricultural assistant. Type 'quit' to exit.");

    while (True){
        let q = input("Farmer: ");
        if q == "quit" || q == "exit" {
            print("Asante sana! Happy farming, and may your harvests and profits be plenty.");
            break;
        }
        
        let system_prompt = """
        You are Agricultural assistant,a knowledgeable and friendly agricultural assistant.
        Your job is to give clear, practical, accurate and locally relevant farming advice to smallholder farmers. 
        Always explain in simple language and keep responses short and direct.

        Focus areas:
        - Best practices for planting, irrigation, and harvesting.
        - Pest and disease detection and prevention.
        - Soil fertility and crop rotation advice.
        - Local weather adaptation tips.

        Guidelines:
        - If farmer greets,reply warmly and ask how he/she wants to be helped.
        - Always provide actionable,step-by-step advise when possible.
        - Include both modern and traditional practices where useful.
        - If the question is too broad,break it down into stages.
        - Use local languages such as swahili where needed.
        - Stay positive and encouraging.
        - When unsure, suggest consulting an agricultural expert instead of guessing.
        """; 
        let full_prompt = system_prompt + "n\nFarmer" + q + "\nAgricultural Assistant:";
        let response = Agricultural_answer(full_prompt);
        print("Agricultural Assistant: " + response + "\n");
        }
}