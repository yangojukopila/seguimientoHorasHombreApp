import { Injectable } from '@angular/core';
import { SupabaseService } from './supabase.service';
import { Project } from '../models';

@Injectable({
    providedIn: 'root'
})
export class ProjectService {
    constructor(private supabase: SupabaseService) { }

    async getAll() {
        return await this.supabase
            .from('projects')
            .select('*')
            .order('name');
    }

    async getById(id: string) {
        return await this.supabase
            .from('projects')
            .select('*')
            .eq('id', id)
            .single();
    }

    async create(project: Partial<Project>) {
        return await this.supabase
            .from('projects')
            .insert(project)
            .select()
            .single();
    }

    async update(id: string, project: Partial<Project>) {
        return await this.supabase
            .from('projects')
            .update(project)
            .eq('id', id)
            .select()
            .single();
    }

    async delete(id: string) {
        return await this.supabase
            .from('projects')
            .delete()
            .eq('id', id);
    }

    async toggleStatus(id: string, status: 'active' | 'closed') {
        return await this.update(id, { status });
    }
}
