from database import views
from rest_framework import routers

router = routers.DefaultRouter()
router.register(r'plugin/users', views.DatabaseUsers,
                basename='DatabaseUsers')
