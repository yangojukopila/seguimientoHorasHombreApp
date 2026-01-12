import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable } from 'rxjs';
import { SupabaseService } from './supabase.service';
import { User } from '@supabase/supabase-js';

@Injectable({
    providedIn: 'root'
})
export class AuthService {
    private currentUserSubject = new BehaviorSubject<User | null>(null);
    public currentUser$: Observable<User | null> = this.currentUserSubject.asObservable();

    constructor(
        private supabase: SupabaseService,
        private router: Router
    ) {
        // Check for existing session
        this.supabase.auth.getSession().then(({ data: { session } }) => {
            this.currentUserSubject.next(session?.user ?? null);
        });

        // Listen for auth changes
        this.supabase.auth.onAuthStateChange((event, session) => {
            this.currentUserSubject.next(session?.user ?? null);
        });
    }

    get currentUser(): User | null {
        return this.currentUserSubject.value;
    }

    get isAuthenticated(): boolean {
        return !!this.currentUser;
    }

    async signIn(email: string, password: string): Promise<{ error: any }> {
        const { error } = await this.supabase.auth.signInWithPassword({
            email,
            password
        });

        if (!error) {
            this.router.navigate(['/admin/dashboard']);
        }

        return { error };
    }

    async signOut(): Promise<void> {
        await this.supabase.auth.signOut();
        this.router.navigate(['/admin/login']);
    }

    async resetPassword(email: string): Promise<{ error: any }> {
        return await this.supabase.auth.resetPasswordForEmail(email);
    }
}
