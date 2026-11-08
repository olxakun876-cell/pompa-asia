/* ============================================================
   Pompa Asia — script.js
   Berisi seluruh logika: memuat data JSON, pencarian, filter
   kategori, render kartu, dan modal detail.

   Catatan: file ini memakai fetch(), jadi situs HARUS dibuka
   melalui web server (http:// atau https://). Membuka langsung
   dengan double-click (file://) akan diblokir browser.
   ============================================================ */

(function () {
  "use strict";

  /* ------------------------------------------------------------
     1. KONFIGURASI
     ------------------------------------------------------------ */
  const SUMBER_DATA = "data/pompa.json"; // lokasi file data
  const GAMBAR_CADANGAN = "assets/img/placeholder-pompa.svg"; // jika gambar gagal dimuat

  // State (data yang sedang aktif di halaman)
  const state = {
    semua: [],        // seluruh data dari JSON
    hasil: [],        // data setelah difilter
    kataKunci: "",    // isi kolom pencarian
    kategori: "semua" // kategori terpilih
  };

  /* ------------------------------------------------------------
     2. REFERENSI ELEMEN DOM
     ------------------------------------------------------------ */
  const el = {
    grid: document.getElementById("grid"),
    inputCari: document.getElementById("inputCari"),
    filter: document.getElementById("filterKategori"),
    btnReset: document.getElementById("btnReset"),
    jumlah: document.getElementById("jumlahHasil"),
    status: document.getElementById("status"),
    modal: document.getElementById("modal"),
    dialog: document.querySelector(".modal__dialog"),
    modalGambar: document.getElementById("modalGambar"),
    modalKategori: document.getElementById("modalKategori"),
    modalJudul: document.getElementById("modalJudul"),
    modalDeskripsi: document.getElementById("modalDeskripsi"),
    modalKapasitas: document.getElementById("modalKapasitas"),
    modalHead: document.getElementById("modalHead"),
    modalDaya: document.getElementById("modalDaya"),
    modalMerek: document.getElementById("modalMerek"),
    spekMerek: document.getElementById("spekMerek"),
    modalAplikasi: document.getElementById("modalAplikasi"),
    tahun: document.getElementById("tahun")
  };

  let pemicuModal = null; // tombol yang membuka modal (untuk mengembalikan fokus)

  /* ------------------------------------------------------------
     3. UTILITAS
     ------------------------------------------------------------ */

  // Mengamankan teks sebelum dimasukkan ke innerHTML (mencegah HTML injection)
  function escapeHtml(nilai) {
    return String(nilai ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  // Menampilkan pesan status (loading / error / kosong)
  function tampilkanStatus(pesan, tipe) {
    el.status.textContent = pesan;
    el.status.classList.toggle("status--error", tipe === "error");
    el.status.hidden = false;
  }

  function sembunyikanStatus() {
    el.status.hidden = true;
  }

  /* ------------------------------------------------------------
     4. MEMUAT DATA DARI JSON
     ------------------------------------------------------------ */
  async function muatData() {
    tampilkanStatus("Memuat data pompa…");

    try {
      const respons = await fetch(SUMBER_DATA, { cache: "no-cache" });

      if (!respons.ok) {
        throw new Error("HTTP " + respons.status);
      }

      const data = await respons.json();

      if (!Array.isArray(data)) {
        throw new Error("Format data tidak valid (harus berupa array).");
      }

      state.semua = data;
      isiFilterKategori();
      bacaParameterURL(); // dukung tautan seperti ?q=centrifugal&kategori=Booster
      terapkanFilter();
    } catch (err) {
      console.error("[Pompa Asia] Gagal memuat data:", err);
      el.grid.innerHTML = "";
      el.jumlah.textContent = "";
      tampilkanStatus(
        "Gagal memuat data pompa. Pastikan file data/pompa.json tersedia dan halaman dibuka lewat web server (bukan file://).",
        "error"
      );
    }
  }

  /* ------------------------------------------------------------
     5. FILTER KATEGORI (opsi dibuat otomatis dari data)
     Menambah kategori baru di pompa.json otomatis muncul di sini.
     ------------------------------------------------------------ */
  function isiFilterKategori() {
    const daftar = Array.from(
      new Set(state.semua.map((p) => p.kategori).filter(Boolean))
    ).sort((a, b) => a.localeCompare(b, "id"));

    // Hapus opsi lama (kecuali "Semua Kategori")
    el.filter.querySelectorAll("option:not([value='semua'])").forEach((o) => o.remove());

    daftar.forEach((kategori) => {
      const opsi = document.createElement("option");
      opsi.value = kategori;
      opsi.textContent = kategori;
      el.filter.appendChild(opsi);
    });
  }

  /* ------------------------------------------------------------
     6. FILTERING
     ------------------------------------------------------------ */
  function terapkanFilter() {
    const kata = state.kataKunci.trim().toLowerCase();

    state.hasil = state.semua.filter((p) => {
      const cocokKategori = state.kategori === "semua" || p.kategori === state.kategori;

      const kolomTeks = [p.nama, p.kategori, p.merek, p.deskripsi, p.aplikasi]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const cocokKata = kata === "" || kolomTeks.includes(kata);

      return cocokKategori && cocokKata;
    });

    renderKartu(state.hasil);
    perbaruiInfo();
    perbaruiURL();
  }

  function perbaruiInfo() {
    const jumlah = state.hasil.length;
    const total = state.semua.length;

    el.jumlah.textContent = `Menampilkan ${jumlah} dari ${total} pompa`;

    if (total === 0) {
      tampilkanStatus("Belum ada data pompa. Tambahkan data pada file data/pompa.json.");
    } else if (jumlah === 0) {
      tampilkanStatus("Tidak ada pompa yang cocok. Coba kata kunci lain atau reset filter.");
    } else {
      sembunyikanStatus();
    }
  }

  /* ------------------------------------------------------------
     7. RENDER KARTU
     ------------------------------------------------------------ */
  function renderKartu(daftar) {
    if (daftar.length === 0) {
      el.grid.innerHTML = "";
      return;
    }

    el.grid.innerHTML = daftar
      .map(
        (p, i) => `
      <article class="card" role="listitem" style="--i: ${i}">
        <div class="card__media">
          <img src="${escapeHtml(p.gambar)}"
               alt="Ilustrasi ${escapeHtml(p.nama)}"
               width="600" height="400" loading="lazy" decoding="async" />
          <span class="card__badge">${escapeHtml(p.kategori)}</span>
        </div>
        <div class="card__body">
          <h3 class="card__title">${escapeHtml(p.nama)}</h3>

          <dl class="card__spec">
            <div>
              <dt>Kapasitas</dt>
              <dd>${escapeHtml(p.kapasitas)}</dd>
            </div>
            <div>
              <dt>Head</dt>
              <dd>${escapeHtml(p.head)}</dd>
            </div>
          </dl>

          <div class="card__foot">
            <span class="card__daya">${escapeHtml(p.daya)}</span>
            <button type="button" class="btn btn--primary btn--sm" data-id="${escapeHtml(p.id)}">
              Detail<span class="sr-only"> ${escapeHtml(p.nama)}</span>
            </button>
          </div>
        </div>
      </article>`
      )
      .join("");
  }

  /* ------------------------------------------------------------
     8. MODAL DETAIL
     ------------------------------------------------------------ */
  function bukaModal(id, pemicu) {
    const pompa = state.semua.find((p) => String(p.id) === String(id));
    if (!pompa) return;

    pemicuModal = pemicu || null;

    // Isi konten modal
    el.modalGambar.src = pompa.gambar || GAMBAR_CADANGAN;
    el.modalGambar.alt = "Ilustrasi " + (pompa.nama || "pompa");
    el.modalKategori.textContent = pompa.kategori || "-";
    el.modalJudul.textContent = pompa.nama || "-";
    el.modalDeskripsi.textContent = pompa.deskripsi || "";
    el.modalKapasitas.textContent = pompa.kapasitas || "-";
    el.modalHead.textContent = pompa.head || "-";
    el.modalDaya.textContent = pompa.daya || "-";

    // Merek hanya ditampilkan jika datanya ada
    const adaMerek = Boolean(pompa.merek);
    el.spekMerek.hidden = !adaMerek;
    el.modalMerek.textContent = pompa.merek || "";

    // Aplikasi hanya ditampilkan jika datanya ada
    const adaAplikasi = Boolean(pompa.aplikasi);
    el.modalAplikasi.hidden = !adaAplikasi;
    el.modalAplikasi.textContent = pompa.aplikasi || "";

    // Tampilkan modal
    el.modal.hidden = false;
    document.body.classList.add("is-locked");
    el.modal.querySelector(".modal__close").focus();
  }

  function tutupModal() {
    el.modal.hidden = true;
    document.body.classList.remove("is-locked");

    // Kembalikan fokus ke tombol "Detail" yang tadi diklik
    if (pemicuModal) {
      pemicuModal.focus();
      pemicuModal = null;
    }
  }

  // Jaga fokus keyboard tetap di dalam modal selama modal terbuka
  function jebakFokus(e) {
    if (e.key !== "Tab") return;

    const fokusable = el.dialog.querySelectorAll(
      'a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    if (fokusable.length === 0) return;

    const pertama = fokusable[0];
    const terakhir = fokusable[fokusable.length - 1];

    if (e.shiftKey && document.activeElement === pertama) {
      e.preventDefault();
      terakhir.focus();
    } else if (!e.shiftKey && document.activeElement === terakhir) {
      e.preventDefault();
      pertama.focus();
    }
  }

  /* ------------------------------------------------------------
     9. SINKRONISASI URL (?q=...&kategori=...)
     Berguna agar hasil pencarian bisa dibagikan / di-bookmark.
     ------------------------------------------------------------ */
  function perbaruiURL() {
    if (!window.history || !window.history.replaceState) return;

    const params = new URLSearchParams();
    if (state.kataKunci.trim()) params.set("q", state.kataKunci.trim());
    if (state.kategori !== "semua") params.set("kategori", state.kategori);

    const query = params.toString();
    const urlBaru = window.location.pathname + (query ? "?" + query : "") + window.location.hash;

    try {
      window.history.replaceState(null, "", urlBaru);
    } catch (err) {
      /* diabaikan: terjadi pada protokol file:// */
    }
  }

  function bacaParameterURL() {
    const params = new URLSearchParams(window.location.search);
    const q = params.get("q");
    const kategori = params.get("kategori");

    if (q) {
      state.kataKunci = q;
      el.inputCari.value = q;
    }

    if (kategori && state.semua.some((p) => p.kategori === kategori)) {
      state.kategori = kategori;
      el.filter.value = kategori;
    }
  }

  /* ------------------------------------------------------------
     10. EVENT LISTENER
     ------------------------------------------------------------ */

  // Pencarian: setiap kali pengguna mengetik
  el.inputCari.addEventListener("input", function () {
    state.kataKunci = this.value;
    terapkanFilter();
  });

  // Filter kategori
  el.filter.addEventListener("change", function () {
    state.kategori = this.value;
    terapkanFilter();
  });

  // Reset filter
  el.btnReset.addEventListener("click", function () {
    state.kataKunci = "";
    state.kategori = "semua";
    el.inputCari.value = "";
    el.filter.value = "semua";
    terapkanFilter();
    el.inputCari.focus();
  });

  // Delegasi klik untuk tombol "Detail"
  el.grid.addEventListener("click", function (e) {
    const tombol = e.target.closest("button[data-id]");
    if (tombol) bukaModal(tombol.dataset.id, tombol);
  });

  // Jika gambar kartu gagal dimuat, pakai gambar cadangan
  // (event "error" tidak bubbling, jadi harus memakai capture)
  el.grid.addEventListener(
    "error",
    function (e) {
      const img = e.target;
      if (img.tagName === "IMG" && !img.dataset.cadangan) {
        img.dataset.cadangan = "1";
        img.src = GAMBAR_CADANGAN;
      }
    },
    true
  );

  el.modalGambar.addEventListener("error", function () {
    if (!this.dataset.cadangan) {
      this.dataset.cadangan = "1";
      this.src = GAMBAR_CADANGAN;
    }
  });

  // Tutup modal: klik overlay, tombol X, atau elemen ber-atribut data-close
  el.modal.addEventListener("click", function (e) {
    if (e.target.closest("[data-close]")) tutupModal();
  });

  // Tutup modal dengan tombol Escape
  document.addEventListener("keydown", function (e) {
    if (el.modal.hidden) return;

    if (e.key === "Escape") {
      tutupModal();
    } else {
      jebakFokus(e);
    }
  });

  /* ------------------------------------------------------------
     11. INISIALISASI
     ------------------------------------------------------------ */
  el.tahun.textContent = new Date().getFullYear();
  muatData();
})();
