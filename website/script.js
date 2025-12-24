// Screenshot Carousel
document.addEventListener('DOMContentLoaded', () => {
    const screenshots = document.querySelectorAll('.screenshot');
    const dots = document.querySelectorAll('.screenshot-dots .dot');
    const prevBtn = document.querySelector('.nav-btn.prev');
    const nextBtn = document.querySelector('.nav-btn.next');
    
    let currentIndex = 0;
    let autoplayInterval;

    function showScreenshot(index) {
        // Handle wrapping
        if (index >= screenshots.length) index = 0;
        if (index < 0) index = screenshots.length - 1;
        
        currentIndex = index;
        
        // Update screenshots
        screenshots.forEach((screenshot, i) => {
            screenshot.classList.toggle('active', i === currentIndex);
        });
        
        // Update dots
        dots.forEach((dot, i) => {
            dot.classList.toggle('active', i === currentIndex);
        });
    }

    function nextScreenshot() {
        showScreenshot(currentIndex + 1);
    }

    function prevScreenshot() {
        showScreenshot(currentIndex - 1);
    }

    function startAutoplay() {
        autoplayInterval = setInterval(nextScreenshot, 5000);
    }

    function stopAutoplay() {
        clearInterval(autoplayInterval);
    }

    // Event listeners
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            stopAutoplay();
            nextScreenshot();
            startAutoplay();
        });
    }

    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            stopAutoplay();
            prevScreenshot();
            startAutoplay();
        });
    }

    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            stopAutoplay();
            showScreenshot(index);
            startAutoplay();
        });
    });

    // Start autoplay
    startAutoplay();

    // Pause on hover
    const container = document.querySelector('.screenshots-container');
    if (container) {
        container.addEventListener('mouseenter', stopAutoplay);
        container.addEventListener('mouseleave', startAutoplay);
    }

    // Smooth scroll for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Navbar background on scroll
    const navbar = document.querySelector('.navbar');
    let lastScroll = 0;

    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 50) {
            navbar.style.background = 'rgba(10, 10, 15, 0.95)';
        } else {
            navbar.style.background = 'rgba(10, 10, 15, 0.8)';
        }
        
        lastScroll = currentScroll;
    });

    // Add animation on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe elements for animation
    document.querySelectorAll('.feature, .value, .app-showcase, .about-content, .contact-card').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

