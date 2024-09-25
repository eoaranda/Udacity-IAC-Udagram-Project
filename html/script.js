document.getElementById('followBtn').addEventListener('click', function () {
    const followBtn = document.getElementById('followBtn');
    if (followBtn.innerText === 'Follow') {
        followBtn.innerText = 'Following';
        followBtn.style.backgroundColor = '#e0e0e0';
        followBtn.style.color = '#000';
    } else {
        followBtn.innerText = 'Follow';
        followBtn.style.backgroundColor = '#3897f0';
        followBtn.style.color = '#fff';
    }
});
