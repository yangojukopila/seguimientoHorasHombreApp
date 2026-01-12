import { Routes } from '@angular/router';

export const routes: Routes = [
    { path: '', redirectTo: '/kiosk', pathMatch: 'full' },
    {
        path: 'kiosk',
        loadChildren: () => import('./kiosk/kiosk.module').then(m => m.KioskModule)
    },
    {
        path: 'admin',
        loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
    }
];
