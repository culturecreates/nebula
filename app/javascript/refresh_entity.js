import * as bootstrap from "bootstrap";

document.addEventListener("DOMContentLoaded", function () {
    const btn = document.getElementById("refresh-entity-btn");
    if (!btn) return;

    const modal = new bootstrap.Modal(document.getElementById("dryrunModal"));
    const modalBody = document.getElementById("dryrunModalBody");
    const okBtn = document.getElementById("dryrunModalOk");

    btn.addEventListener("click", function () {
        // Show modal immediately with "Calculating..." message
        modalBody.innerHTML = "<div class='text-center'><span class='spinner-border spinner-border-sm' role='status' aria-hidden='true'></span> Calculating...</div>";
        modal.show();

        // Now call the controller
        fetch("/maintenance/refresh_entity", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({ uri: btn.dataset.uri, dryrun: true })
        })
            .then(response => {
                if (!response.ok) {
                    // Handle 500 or other errors
                    throw new Error(`Server error: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (typeof data.message === "undefined") {
                    modal.hide();
                    window.location.reload();
                    return;
                }
                modalBody.innerHTML = data.message;

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
            }) .catch(error => {
                // Handle error here
                modalBody.innerHTML = `<div class='text-danger'>${error.message}</div>`;
            });
    });
});