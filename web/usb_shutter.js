/**
 * WebUSB PTP (Picture Transfer Protocol) Shutter Listener untuk DiPhoto
 * Mendukung kamera eksternal (Sony ZV-E10, Canon, Nikon) via USB
 */
window.DiPhotoUSB = {
  device: null,
  isListening: false,
  shutterCallback: null,
  statusCallback: null,

  // Registrasi callback dari Flutter
  onShutterPressed: function(cb) {
    this.shutterCallback = cb;
  },

  onStatusChange: function(cb) {
    this.statusCallback = cb;
  },

  updateStatus: function(msg, isConnected) {
    if (this.statusCallback) {
      this.statusCallback(msg, isConnected);
    }
  },

  // 1. Inisialisasi & Hubungkan Perangkat USB Kamera
  connectCamera: async function() {
    if (!navigator.usb) {
      this.updateStatus("WebUSB tidak didukung di browser ini. Gunakan Chrome/Edge desktop.", false);
      return false;
    }

    try {
      // Filter: Vendor Sony (0x054C), Canon (0x04A9), Nikon (0x04B0), Fujifilm (0x04CB), Panasonic (0x04DA), atau Still Imaging PTP (0x06)
      const filters = [
        { vendorId: 0x054C }, // Sony
        { vendorId: 0x04A9 }, // Canon
        { vendorId: 0x04B0 }, // Nikon
        { vendorId: 0x04CB }, // Fujifilm
        { vendorId: 0x04DA }, // Panasonic
        { classCode: 0x06 }   // Still Imaging Class (PTP / MTP)
      ];

      try {
        this.device = await navigator.usb.requestDevice({ filters: filters });
      } catch (filterErr) {
        // Fallback: Jika pengguna memilih kamera yang VID nya berbeda / mode composite
        this.device = await navigator.usb.requestDevice({ filters: [] });
      }

      await this.device.open();

      if (this.device.configuration === null) {
        await this.device.selectConfiguration(1);
      }

      // Cari interface USB Imaging / PTP
      let ptpInterface = null;
      for (const iface of this.device.configuration.interfaces) {
        for (const alt of iface.alternates) {
          if (alt.interfaceClass === 0x06 || alt.interfaceSubclass === 0x01) {
            ptpInterface = iface;
            break;
          }
        }
        if (ptpInterface) break;
      }

      if (!ptpInterface && this.device.configuration.interfaces.length > 0) {
        // Fallback interface pertama
        ptpInterface = this.device.configuration.interfaces[0];
      }

      if (ptpInterface) {
        await this.device.claimInterface(ptpInterface.interfaceNumber);
      }

      const camName = this.device.productName || "USB Camera";
      this.updateStatus("Terhubung: " + camName, true);

      // Cari endpoint interrupt (IN) untuk mendengarkan event shutter
      this.startListening(ptpInterface);
      return true;
    } catch (err) {
      console.warn("USB connect error:", err);
      this.updateStatus("Gagal menghubungkan USB: " + (err.message || err), false);
      return false;
    }
  },

  // 2. Dengarkan USB Interrupt / Event dari Tombol Shutter
  startListening: async function(ptpInterface) {
    if (!this.device || !this.device.opened) return;
    this.isListening = true;

    // Cari endpoint IN (tipe interrupt atau bulk)
    let inEndpointNumber = 1;
    if (ptpInterface) {
      const endpoints = ptpInterface.alternates[0].endpoints;
      const inEndpoint = endpoints.find(e => e.direction === 'in');
      if (inEndpoint) {
        inEndpointNumber = inEndpoint.endpointNumber;
      }
    }

    // Dengarkan event terus-menerus
    while (this.isListening && this.device && this.device.opened) {
      try {
        const result = await this.device.transferIn(inEndpointNumber, 64);
        if (result && result.data && result.data.byteLength > 0) {
          // Event PTP Shutter / Button Press diterima dari kamera
          console.log("[DiPhoto USB] Shutter Event received:", result.data);
          if (this.shutterCallback) {
            this.shutterCallback();
          }
        }
      } catch (err) {
        if (err.name === 'NetworkError' || !this.device.opened) {
          this.updateStatus("Koneksi USB kamera terputus.", false);
          this.disconnect();
          break;
        }
        // Jeda sejenak sebelum polling kembali
        await new Promise(r => setTimeout(r, 100));
      }
    }
  },

  // 3. Putuskan sambungan USB
  disconnect: async function() {
    this.isListening = false;
    if (this.device) {
      try {
        await this.device.close();
      } catch (_) {}
      this.device = null;
    }
    this.updateStatus("Kamera USB terputus.", false);
  }
};

// Event listener jika kabel USB dicabut fisik
if (navigator.usb) {
  navigator.usb.addEventListener('disconnect', (event) => {
    if (window.DiPhotoUSB.device === event.device) {
      console.log("[DiPhoto USB] Device disconnected physically.");
      window.DiPhotoUSB.disconnect();
    }
  });
}
