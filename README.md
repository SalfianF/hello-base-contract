# HelloBase — Base Mainnet Smart Contract

Contract simpel buat deploy di **Base mainnet**. Cocok buat claim role **"Contract Deployed: 1"** di [Base Builders & Founders Guild](https://guild.xyz/base/builders-founders).

---

## 📁 Struktur File

```
hello-base-contract/
├── contracts/
│   ├── HelloBase.sol        ← Smart contract pertama
│   └── BridgingToBase.sol   ← Smart contract kedua
├── scripts/
│   └── deploy.js           ← Script deploy
├── hardhat.config.js       ← Config Hardhat + Base network
├── .env.example            ← Template env (isi private key)
├── .gitignore
├── package.json
└── README.md               ← Ini dia!
```

---

## 🚀 Cara Deploy (Step by Step)

> ⚠️ **PENTING**: Pastikan wallet kamu punya minimal **0.0005 ETH** di Base mainnet buat gas fee.

### Langkah 1: Download Project

Buka terminal/CMD di PC kamu, jalanin:

```bash
# Clone project ini (ganti <USERNAME> sama username GitHub kamu)
git clone https://github.com/salfianf/hello-base-contract.git
cd hello-base-contract
```

Atau kalo manual: download ZIP, extract, masuk folder.

### Langkah 2: Install Dependency

```bash
npm install
```

Tunggu selesai (~1 menit).

### Langkah 3: Setup Private Key

```bash
cp .env.example .env
```

Buka file **`.env`** dengan notepad/text editor. Isi:

```
PRIVATE_KEY=0x1234567890abcdef...  ← private key wallet kamu (ADA 0x DI DEPAN)
```

> 🛑 **JANGAN COMMIT .env ke GitHub!** Udah ada di .gitignore kok.

### Langkah 4: Deploy ke Base Mainnet

```bash
npm run deploy
```

Kalo berhasil, bakal muncul:

```
Deploying with account: 0x...
Balance: 0.XXX ETH

✅ HelloBase deployed to: 0x...
🔗 Explorer: https://basescan.org/address/0x...
```

### Langkah 5: Claim Role di Guild

1. Buka https://guild.xyz/base/builders-founders
2. Connect **wallet** kamu (yang pake buat deploy)
3. Connect **GitHub** akun `salfianf`
4. Nanti otomatis dapet role **"Contract Deployed: 1"** 🎉

---

## 🔧 Cara Deploy Manual via Remix (Alternatif)

Kalo gak mau install npm/Hardhat, bisa pake Remix IDE:

1. Buka https://remix.ethereum.org/
2. Buat file baru `HelloBase.sol`
3. **Copy paste** isi dari `contracts/HelloBase.sol`
4. Tab **Solidity Compiler** → Compile `HelloBase.sol`
5. Tab **Deploy & Run Transactions**
   - Environment: pilih **Injected Provider - MetaMask**
   - Switch MetaMask ke **Base Mainnet**
   - Deploy dengan parameter: `"Hello Base! Built on Ethereum 🛡️"`
   - Confirm transaksi di MetaMask

---

## ✅ Verifikasi di BaseScan (Opsional)

Biar kontrak kamu keliatan verified (centang hijau):

```bash
# Isi dulu BASESCAN_API_KEY di .env
# Daftar API Key gratis: https://basescan.org/register

npx hardhat verify --network base <ADDRESS_KONTRAK> "Hello Base! Built on Ethereum 🛡️"
```

---

## 📞 Kontrak

```solidity
contract HelloBase {
    string public message;       // Pesan yang bisa diubah
    address public owner;        // Kamu (yang deploy)
    uint256 public deployTime;   // Timestamp deploy

    function setMessage(string calldata _message)  // Ganti pesan (hanya owner)
    function getInfo()                             // Lihat semua info
}
```

---

Dibuat oleh Dina ❤️
