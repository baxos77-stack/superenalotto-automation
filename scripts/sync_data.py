import os
import re
import requests
from datetime import datetime

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Errore: Credenziali Supabase mancanti nei segreti di GitHub!")
    exit(1)

def fetch_and_sync():
    print("🛰️ Connessione alla nuova sorgente estrazioni...")
    # Usiamo un portale alternativo stabile e non protetto da blocchi aggressivi per i bot
    url = 'https://www.estrazionedellotto.it/estrazioni-superenalotto.htm'
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }

    try:
        response = requests.get(url, headers=headers, timeout=15)
        if response.status_code != 200:
            print(f"❌ Errore sorgente: Codice {response.status_code}")
            return
            
        html = response.text
        dati_validati = []
        oggi = datetime.now().date()

        # Cerchiamo i blocchi delle estrazioni nella pagina tramite espressioni regolari (Regex)
        # Questo ci permette di estrarre data, combinazione principale, jolly e superstar
        pattern_blocchi = re.compile(
            r'Estrazione del\s+(\d{2}/\d{2}/\d{4}).*?'  # Cattura la data
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n1
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n2
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n3
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n4
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n5
            r'font-num-se.*?">(\d+)<\/span>.*?'          # n6
            r'font-num-jolly.*?">(\d+)<\/span>.*?'       # Jolly
            r'font-num-ss.*?">(\d+)<\/span>',            # Superstar
            re.DOTALL
        )

        matches = pattern_blocchi.findall(html)
        print(f"🔎 Trovate {len(matches)} estrazioni recenti nella pagina HTML.")

        for match in matches:
            raw_date, n1, n2, n3, n4, n5, n6, jolly, superstar = match
            
            # Convertiamo la data da DD/MM/YYYY a YYYY-MM-DD per Supabase
            try:
                draw_date = datetime.strptime(raw_date, "%d/%m/%Y").date()
                clean_date_str = draw_date.strftime("%Y-%m-%d")
            except ValueError:
                continue

            if draw_date > oggi:
                continue

            try:
                dati_validati.append({
                    "data": clean_date_str,
                    "n1": int(n1), "n2": int(n2), "n3": int(n3), 
                    "n4": int(n4), "n5": int(n5), "n6": int(n6), 
                    "jolly": int(jolly), "superstar": int(superstar)
                })
            except (ValueError, TypeError):
                continue

        if not dati_validati:
            print("⚠️ Nessun dato valido estratto dalla pagina.")
            return

        print(f"📦 Elaborazione completata. Pronti al caricamento {len(dati_validati)} concorsi.")

        # Connessione a Supabase
        supabase_endpoint = f"{SUPABASE_URL}/rest/v1/estrazioni"
        headers_supabase = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates"
        }

        # Invio a blocchi (chunking)
        chunk_size = 100
        for i in range(0, len(dati_validati), chunk_size):
            chunk = dati_validati[i:i + chunk_size]
            res = requests.post(supabase_endpoint, json=chunk, headers=headers_supabase)
            if res.status_code in [200, 201]:
                print(f"🚀 Blocco {i//chunk_size + 1} inviato con successo.")
            else:
                print(f"❌ Errore Supabase: {res.status_code} - {res.text}")

    except Exception as e:
        print(f"💥 Errore durante l'esecuzione: {e}")

if __name__ == "__main__":
    fetch_and_sync()