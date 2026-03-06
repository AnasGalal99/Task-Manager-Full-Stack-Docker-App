# ----- Builder Stage -----
FROM python:3.11-alpine AS builder

WORKDIR /app

# تحميل الأدوات الأساسية لعملية الـ Build
RUN apk add --no-cache gcc musl-dev postgresql-dev python3-dev

# نسخ ملف requirements.txt لوحده الأول عشان نستفيد من الـ layer cache
COPY requirements.txt .

# تثبيت الـ Dependencies
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt

# ----- Runtime Stage -----
FROM python:3.11-alpine

WORKDIR /app

# تحميل الحزم الأساسية (على الأقل libpq و wget زي ما هو مطلوب)
RUN apk add --no-cache libpq wget

# نسخ الـ wheels من الـ Builder stage وتثبيتها
COPY --from=builder /usr/src/app/wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# إنشاء Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# نسخ باقي ملفات المشروع
COPY . .

# تغيير الصلاحيات للـ user الجديد
RUN chown -R appuser:appgroup /app
USER appuser

# إعداد الـ HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:8000/api/health || exit 1

# تشغيل التطبيق باستخدام gunicorn
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8000", "flask_app:app"]