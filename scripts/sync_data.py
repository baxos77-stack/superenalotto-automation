import os
import requests
from datetime import datetime

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Errore: Credenziali Supabase mancanti nei segreti di GitHub!")
    exit(1)

def fetch_and_sync():
    print("🛰️ Connessione all'API...")
    url = 'https://gmapis.net/api/v1/superenalotto/history'
    
    try:
        response = requests.get(url, timeout=15)
        if response.status_code != 200:
            print(f"❌ Errore API: Codice {response.status_code}")
            return
            
        json_data = response.json()
        raw_draws = json_data.get('data', []) or json_data.get('results', [])
        
        dati_validati = []
        oggi = datetime.now().date()

        for draw in raw_draws:
            raw_date = draw.get('date') or draw.get('data')
            if not raw_date:
                continue
            
            clean_date_str = str(raw_date).split('T')[0]
            try:
                draw_date = datetime.strptime(clean_date_str, "%Y-%m-%d").date()
            except ValueError:
                continue

            if draw_date > oggi:
                continue

            try:
                n1 = int(draw.get('n1', 0))
                n2 = int(draw.get('n2', 0))
                n3 = int(draw.get('n3', 0))
                n4 = int(draw.get('n4', 0))
                n5 = int(draw.get('n5', 0))
                n6 = int(draw.get('n6', 0))
                jolly = int(draw.get('jolly', 0))
                superstar = int(draw.get('superstar', 0))
            except (ValueError, TypeError):
                continue

            if n1 <= 0 or n2 <= 0 or n6 <= 0:
                continue

            dati_validati.append({
                "data": clean_date_str, "n1": n1, "n2": n2, "n3": n3, 
                "n4": n4, "n5": n5, "n6": n6, "jolly": jolly, "superstar": superstar
            })

        if not dati_validati:
            print("⚠️ Nessun dato valido.")
            return

        supabase_endpoint = f"{SUPABASE_URL}/rest/v1/estrazioni"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates"
        }

        chunk_size = 100
        for i in range(0, len(dati_validati), chunk_size):
            chunk = dati_validati[i:i + chunk_size]
            res = requests.post(supabase_endpoint, json=chunk, headers=headers)
            if res.status_code in [200, 201]:
                print(f"🚀 Blocco {i//chunk_size + 1} inviato.")
            else:
                print(f"❌ Errore Supabase: {res.status_code}")

    except Exception as e:
        print(f"💥 Errore: {e}")

if __name__ == "__main__":
    fetch_and_sync()