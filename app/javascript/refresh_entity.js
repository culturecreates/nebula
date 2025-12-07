import * as bootstrap from "bootstrap";

document.addEventListener("DOMContentLoaded", function () {
    const btn = document.getElementById("refresh-entity-btn");
    if (!btn) return;

    const modal = new bootstrap.Modal(document.getElementById("dryrunModal"));
    const modalBody = document.getElementById("dryrunModalBody");
    const okBtn = document.getElementById("dryrunModalOk");
    const flashData = document.getElementById("flash-data");

    if (flashData) {
        const notice = flashData.dataset.flashNotice;
        const alert = flashData.dataset.flashAlert;
        if (notice || alert) {
            modalBody.innerHTML = notice
                ? `<div class="alert alert-success">${notice}</div>`
                : `<div class="alert alert-danger">${alert}</div>`;
            const modal = new bootstrap.Modal(modalElement);
            modal.show();
        }
    }

    btn.addEventListener("click", function () {
        fetch("/maintenance/refresh_entity", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({ uri: btn.dataset.uri, dryrun: true })
        })
            .then(response => response.json())
            .then(data => {
                modalBody.innerHTML = data.message;
                modal.show();

                okBtn.onclick = function () {
                    modal.hide();
                    fetch("/maintenance/refresh_entity", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
                        },
                        body: JSON.stringify({ uri: btn.dataset.uri, dryrun: false })
                    })
                        .then(response => response.json())
                        .then(result => {
                            window.location.href = result.redirect_url;
                        });
                };
            });
    });
});