/**
 * GOOGLE APPS SCRIPT UNTUK DIPHOTO (PHOTOBOOTH)
 * 
 * Script ini menerima gambar berformat base64 dari aplikasi DiPhoto
 * lalu menyimpannya ke folder Google Drive tujuan dan mengembalikan link publik / folder link.
 * 
 * CARA DEPLOY:
 * 1. Buka https://script.google.com/
 * 2. Buat project baru (misal: "DiPhoto Drive Uploader").
 * 3. Hapus semua isi di Code.gs, lalu paste seluruh script di bawah ini.
 * 4. Klik tombol "Deploy" (Terapkan) di kanan atas -> Pilih "New deployment" (Penerapan baru).
 * 5. Klik icon roda gigi di samping "Select type" -> Pilih "Web app".
 * 6. Isi pengaturan berikut (PENTING):
 *    - Description: DiPhoto Web App v1
 *    - Execute as: "Me" (Email Google Anda)
 *    - Who has access: "Anyone" (Siapa saja - agar aplikasi bisa mengirim foto tanpa login)
 * 7. Klik "Deploy", lalu klik "Authorize access" dan izinkan akses Google Drive.
 * 8. Salin "Web app URL" (akhiran /exec) dan tempelkan ke aplikasi DiPhoto pada kolom "Google Apps Script URL".
 */

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return createJsonResponse({
        success: false,
        error: "Tidak ada data yang diterima"
      });
    }

    var data;
    try {
      data = JSON.parse(e.postData.contents);
    } catch (parseErr) {
      return createJsonResponse({
        success: false,
        error: "Format data bukan JSON valid: " + parseErr.toString()
      });
    }

    var imageBase64 = data.image;
    var fileName = data.fileName || ("photobooth_" + new Date().getTime() + ".jpg");
    var folderId = data.folderId;

    if (!imageBase64) {
      return createJsonResponse({
        success: false,
        error: "Parameter image (base64) kosong"
      });
    }

    if (!folderId) {
      return createJsonResponse({
        success: false,
        error: "Parameter folderId kosong"
      });
    }

    // Bersihkan header base64 jika ada data:image/jpeg;base64,
    if (imageBase64.indexOf(",") > -1) {
      imageBase64 = imageBase64.split(",")[1];
    }

    // Decode base64 menjadi blob gambar
    var decodedBytes = Utilities.base64Decode(imageBase64);
    var blob = Utilities.newBlob(decodedBytes, "image/jpeg", fileName);

    // Buka folder tujuan di Google Drive
    var folder = DriveApp.getFolderById(folderId.trim());

    // Buat file foto di folder Google Drive
    var file = folder.createFile(blob);

    // Set permission file agar siapapun yang punya link bisa melihat
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    var fileViewLink = file.getUrl();
    var folderLink = "https://drive.google.com/drive/folders/" + folderId.trim();

    return createJsonResponse({
      success: true,
      message: "Foto berhasil diunggah ke Google Drive",
      fileName: fileName,
      fileId: file.getId(),
      link: fileViewLink,
      folderLink: folderLink
    });

  } catch (err) {
    return createJsonResponse({
      success: false,
      error: err.toString()
    });
  }
}

function doGet(e) {
  return createJsonResponse({
    status: "OK",
    message: "DiPhoto Google Apps Script Web App is active and ready."
  });
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
