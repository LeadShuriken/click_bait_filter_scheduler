from django.urls import path, include
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from scheduler import views
from patches import router
from database.urls import router as db_router


class DocsView(APIView):
    """
    RESTFul Documentation
    """
    permission_classes = (IsAuthenticated,)

    def get(self, request, *args, **kwargs):
        apidocs = {
            'cron': request.build_absolute_uri('cron/'),
            'django/users': request.build_absolute_uri('django/users/'),
            # 'django/users/changepassword': request.build_absolute_uri('django/users/changepassword/'),
            # 'django/users/updateprofile': request.build_absolute_uri('django/users/updateprofile'),
            'django/groups': request.build_absolute_uri('django/groups/'),
            'plugin/users': request.build_absolute_uri('plugin/users/')}
        return Response(apidocs)


router = router.DefaultRouter()
router.register(r'django/users', views.UserViewSet)
router.register(r'django/groups', views.GroupViewSet)
router.register(r'cron', views.Cron, basename='Cron')
router.extend(db_router)

urlpatterns = [
    path('', DocsView.as_view()),
    # path('django/users/changepassword/',
    #      views.ChangePasswordView, name='auth_change_password'),
    # path('django/users/updateprofile/',
    #      views.UpdateProfileView, name='auth_update_profile'),
    path('', include(router.urls)),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework'))
]
